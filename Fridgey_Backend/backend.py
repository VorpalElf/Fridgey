from workers import WorkerEntrypoint, Response

class Default(WorkerEntrypoint):
    async def fetch(self, request):
        return Response("Hello World!")

name = "fridgey-backend"
main = "backend.py"
compatibility_date = "2026-06-04"
compatibility_flags = ["python_workers"]