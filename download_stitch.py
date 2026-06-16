import os
import urllib.request

urls = {
    "1_conflict_resolution_tool.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzU5NDdjZDkzMjEyNzQ1NDZiMzY4NjA2ZTdlYmY5MGMxEgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086",
    "2_milestone_reminders.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2NjMzM2NDM4MTQxZjQyYzE4YzdkM2QyOTA3YWVlOTI0EgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086",
    "3_relationship_home_dashboard.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2JkMWU1OGFhY2ZhZDRiZjlhZjk5OTJhYjNlZWViZTg0EgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086",
    "4_couples_emotions_checkin.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzdjMTYzOWJhYTEzYjQyZDE5MjI3Y2Q1NDVkZThjODc1EgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086",
    "5_relationship_confirmed_modal.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzE0ZDgwMWNmY2U1ODQ3NDI5ZTZiMjVmNDY3ZDJiZWYyEgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086",
    "6_relationship_invitation_flow.html": "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sX2FlNDEzYTkyNDU1YTQ5NDA4OWMwZjEyODFmYTM4OTA1EgsSBxCc7bzq0BsYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTg4MTQ3ODExMzgyMjE5NTU5MQ&filename=&opi=89354086"
}

out_dir = "scratch_stitch"
os.makedirs(out_dir, exist_ok=True)

for name, url in urls.items():
    path = os.path.join(out_dir, name)
    print(f"Downloading {name}...")
    try:
        urllib.request.urlretrieve(url, path)
        print(f"Saved to {path}")
    except Exception as e:
        print(f"Failed to download {name}: {e}")
