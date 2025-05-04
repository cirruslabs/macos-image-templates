load("cirrus", "env", "http", "fs", "changes_include")
load("github.com/cirrus-modules/graphql", "rerun_task_if_issue_in_logs")


def on_task_failed(ctx):
  if ctx.payload.data.task.automaticReRun:
    print("Task is already an automatic re-run! Won't even try to re-run it...")
    return
  rerun_task_if_issue_in_logs(ctx.payload.data.task.id, "The network connection was lost")


def on_build_failed(ctx):
  # Only send Slack notifications for failed cron builds[1]
  #
  # [1]: https://cirrus-ci.org/guide/writing-tasks/#cron-builds
  if "Cron" not in ctx.payload.data.build.changeMessageTitle:
    return

  resp = http.post(env.get("SLACK_WEBHOOK_URL"), headers={
    "Content-Type": "application/json",
  }, json_body={
    "text": "Build {build_id} (\"{change_message_title}\") failed on branch \"{branch_name}\" in repository \"{repository_name}\".".format(
      build_id=ctx.payload.data.build.id,
      change_message_title=ctx.payload.data.build.changeMessageTitle,
      branch_name=ctx.payload.data.build.branch,
      repository_name=ctx.payload.data.repository.name,
    ),
    "url": "https://cirrus-ci.com/build/{build_id}".format(
      build_id=ctx.payload.data.build.id,
    ),
  })

  if resp.status_code != 200:
    fail("failed to post message to Slack: got unexpected HTTP {}".format(resp.status_code))

  resp_json = resp.json()

  if resp_json["ok"] != True:
    fail("got error when posting message to Slack: {}".format(resp_json["error"]))


def main(ctx):
  result = fs.read(".ci/cirrus.vanilla.yml")
  if env.get("CIRRUS_TAG") != None:
    result += fs.read(".ci/cirrus.release.yml")
  if env.get("CIRRUS_CRON") == "monthly":
    result += fs.read(".ci/cirrus.base.yml")
    result += fs.read(".ci/cirrus.xcode.yml")
  if env.get("CIRRUS_CRON") == "weekly" or changes_include(".ci/cirrus.runner.yml"):
    result += fs.read(".ci/cirrus.runner.yml")
  return result
