# AI-Powered Firewall Reports with Batch Processing

## Blog Post
https://blog.terenceluk.com/2026/03/scaling-ai-powered-firewall-reports-with-batch-processing-in-azure-logic-apps.html

## Overview
This Logic App generates daily firewall reports using AI-powered analysis and batch processing...

## How It Works
1. **Trigger**: Scheduled trigger runs daily at 2:00 AM
2. **Batch Processing**: Processes firewall logs in 1000-record batches
3. **AI Analysis**: Uses Azure OpenAI to identify threat patterns...

## Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `batchSize` | Number of records per batch | 1000 |
| `openAIDeployment` | Azure OpenAI deployment name | "gpt-4o" |
