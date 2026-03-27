# CyberPatriot Automation Tool

A C# console application that automates CyberPatriot competition tasks by scanning your system and executing remediation commands.

## Features

- **System State Reading**: Parse README files and capture current system configuration
- **Interactive Mode**: Ask for confirmation before executing each remediation
- **Dry Run Mode**: Preview changes without making them
- **Cross-Platform**: Built on .NET 9.0 for Windows, macOS, and Linux
- **Rich Terminal UI**: Beautiful formatted output with Spectre.Console

## Project Structure

```
CyberPatriotAutomation/
├── Models/              # Data classes (TaskResult, SystemInfo)
├── Tasks/               # Base task classes for remediation logic
├── Utilities/           # Helper classes (CommandExecutor, ReadmeParser)
├── Commands/            # CLI command handlers
├── Program.cs           # Entry point
└── CyberPatriotAutomation.csproj
```

## Prerequisites

- .NET 9.0 SDK or later
- Administrator/sudo privileges (for system remediation)

## Installation

1. Clone or download the project
2. Navigate to the project directory:
   ```bash
   cd CyberPatriotAutomation
   ```

3. Restore dependencies:
   ```bash
   dotnet restore
   ```

## Building

```bash
dotnet build
```

## Running

Basic execution:
```bash
dotnet run
```

With README file:
```bash
dotnet run -- --readme path/to/README.md
```

With options:
```bash
dotnet run -- --readme README.md --interactive --dry-run
```

### Command Line Arguments

- `--readme, -r <file>` - Path to the CyberPatriot README file
- `--interactive, -i` - Ask for confirmation before each action (default: enabled)
- `--no-interactive` - Run without user confirmation
- `--dry-run, -d` - Show what would be done without making changes

## Architecture

### Models
- **TaskResult**: Represents the outcome of a task execution
- **SystemInfo**: Stores current system state (services, users, firewall rules, etc.)

### Tasks
- **BaseTask**: Abstract base class for all remediation tasks
  - `ReadSystemStateAsync()`: Gather current system information
  - `ExecuteAsync()`: Perform the remediation
  - `VerifyAsync()`: Confirm the fix was successful

### Utilities
- **CommandExecutor**: Execute system commands with optional elevation
  - `ExecuteAsync()`: Run a command normally
  - `ExecuteElevatedAsync()`: Run with admin/sudo privileges
- **ReadmeParser**: Parse README files to extract task requirements

## Usage Example

```csharp
// Create a task implementation
public class DisableUnneededService : BaseTask
{
    public DisableUnneededService()
    {
        Name = "Disable Unnecessary Services";
        Description = "Disable services not required for the system";
    }

    public override async Task<SystemInfo> ReadSystemStateAsync()
    {
        var (success, output, _) = await CommandExecutor.ExecuteAsync("systemctl", "list-units --type=service");
        // Parse and return system info
        return new SystemInfo();
    }

    public override async Task<TaskResult> ExecuteAsync()
    {
        var (success, _, error) = await CommandExecutor.ExecuteElevatedAsync("systemctl", "disable telemetry");
        return new TaskResult 
        { 
            TaskName = Name,
            Success = success,
            Message = "Service disabled",
            ErrorDetails = error
        };
    }

    public override async Task<bool> VerifyAsync()
    {
        // Verify the service is actually disabled
        return true;
    }
}
```

## Development

### Adding New Tasks

1. Create a new class in `Tasks/` directory
2. Inherit from `BaseTask`
3. Implement the three abstract methods
4. Register in the main application logic

### Example: File Cleaner Task

```csharp
public class CleanTemporaryFiles : BaseTask
{
    // Implementation here
}
```

## Dependencies

- **Spectre.Console** v0.54.0 - Rich terminal output
- **System.CommandLine** v2.0.2 - Command-line argument parsing

## Notes

- Ensure you run with elevated privileges on Windows (Run as Administrator)
- Use `--dry-run` first to preview changes
- Always backup important files before running in production
- The tool is designed for Windows systems but can be adapted for Linux/macOS

## Future Enhancements

- [ ] Implement specific CyberPatriot task modules
- [ ] Add progress tracking and detailed reporting
- [ ] Create task templates for common CyberPatriot categories
- [ ] Add configuration file support
- [ ] Implement logging and audit trail

## License

MIT License - Feel free to modify and distribute

## Support

For issues or suggestions, please refer to the main repository.
