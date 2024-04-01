load("github.com/cirrus-modules/graphql", "rerun_task_if_issue_in_logs")

def on_task_failed(ctx):
    if ctx.payload.data.task.automaticReRun:
        print("Task is already an automatic re-run! Won't even try to re-run it...")
        return
    rerun_task_if_issue_in_logs(ctx.payload.data.task.id, "The network connection was lost")