import subprocess
from fastapi import FastAPI, HTTPException

app = FastAPI()

def run_inverter_command(command: str):
    """Executes the inverter-cli command and returns the result."""
    try:
        # The path to the compiled C++ binary inside the Docker container
        cli_path = "/usr/bin/inverter-cli"
        
        # Execute the command, for example: /usr/bin/inverter-cli -s POP01
        result = subprocess.run(
            [cli_path, "-s", command],
            capture_output=True,
            text=True,
            check=True
        )
        # Assuming the CLI tool returns a success message on stdout
        return {"status": "success", "response": result.stdout.strip()}
    except subprocess.CalledProcessError as e:
        # This error is raised if the command returns a non-zero exit code
        raise HTTPException(
            status_code=500,
            detail=f"Inverter command failed: {e.stderr.strip()}"
        )
    except FileNotFoundError:
        # This error occurs if the inverter-cli binary is not found
        raise HTTPException(
            status_code=500,
            detail=f"Error: The command '{cli_path}' was not found."
        )

@app.post("/set/output_source_priority")
def set_output_source_priority(priority: int):
    """
    Sets the output source priority.
    - 0: Utility first
    - 1: Solar first
    - 2: SBU priority
    """
    if priority not in [0, 1, 2]:
        raise HTTPException(status_code=400, detail="Invalid priority value. Use 0, 1, or 2.")
    
    command = f"POP{priority:02d}"
    return run_inverter_command(command)

@app.post("/set/charger_priority")
def set_charger_priority(priority: int):
    """
    Sets the charger priority.
    - 0: Utility first
    - 1: Solar first
    - 2: Solar and Utility
    - 3: Only Solar charging
    """
    if priority not in [0, 1, 2, 3]:
        raise HTTPException(status_code=400, detail="Invalid priority value. Use 0, 1, 2, or 3.")
    
    command = f"PCP{priority:02d}"
    return run_inverter_command(command)