from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl
from typing import Dict, Any, Optional
import httpx
import uvicorn

app = FastAPI(title="Agentic API Tester Engine")

class APIRequest(BaseModel):
    method: str  # GET, POST, PUT, DELETE
    url: HttpUrl
    headers: Optional[Dict[str, str]] = None
    body: Optional[Dict[str, Any]] = None

@app.get("/")
def read_root():
    return {"status": "Engine is running", "version": "1.0.0"}

@app.post("/execute")
async def execute_api_call(request_data: APIRequest):
    """
    Executes a dynamic API call requested by the agent or Flutter frontend.
    """
    async with httpx.AsyncClient() as client:
        try:
            # Prepare the request
            response = await client.request(
                method=request_data.method.upper(),
                url=str(request_data.url),
                headers=request_data.headers,
                json=request_data.body
            )
            
            # Return the results for the agent to analyze
            return {
                "status_code": response.status_code,
                "headers": dict(response.headers),
                "data": response.json() if "application/json" in response.headers.get("content-type", "") else response.text,
                "time_elapsed_ms": response.elapsed.total_seconds() * 1000
            }
            
        except httpx.RequestError as exc:
            raise HTTPException(status_code=500, detail=f"Request failed: {str(exc)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)