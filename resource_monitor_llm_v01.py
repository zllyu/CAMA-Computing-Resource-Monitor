from openai import AzureOpenAI
import os

with open("/tmp/server_report_2025-07-07.txt") as f:
    report = f.read()

prompt = f"""
You are an assistant helping a system administrator. Based on the server monitoring logs below, generate a concise daily summary report including:

1. List of unreachable servers
2. GPU usage per server (include user, memory, and PID if available)
3. Disk usage details (highlight any volumes with >80% usage)
4. Slurm cluster queue summary
5. Final health check summary and any action recommendations

Monitoring log:
{report}
"""


endpoint = "https://mgh-camca-research-private-e2-openai-service.openai.azure.com/"
model_name = "gpt-4.1-nano"
deployment = "gpt_41_nano_2025_04_14"

subscription_key = ""
api_version = "2024-12-01-preview"

client = AzureOpenAI(
    api_version=api_version,
    azure_endpoint=endpoint,
    api_key=subscription_key,
)

response = client.chat.completions.create(
    model=deployment,
    messages=[{"role": "user", "content": prompt}],
    temperature=0.3
)

print(response.choices[0].message.content)

