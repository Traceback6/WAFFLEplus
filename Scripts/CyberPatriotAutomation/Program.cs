using Spectre.Console;

AnsiConsole.MarkupLine("[bold blue]CyberPatriot Automation Tool[/]");
AnsiConsole.MarkupLine("[dim]Version 1.0.0[/]");
AnsiConsole.WriteLine();

// Parse command line arguments
var cliArgs = Environment.GetCommandLineArgs().Skip(1).ToArray();
var readmeFile = ExtractArgument(cliArgs, "--readme", "-r");
var dryRun = cliArgs.Contains("--dry-run") || cliArgs.Contains("-d");
var interactive = !cliArgs.Contains("--no-interactive");

if (readmeFile != null)
{
    AnsiConsole.MarkupLine($"[yellow]README: {readmeFile}[/]");
}

AnsiConsole.MarkupLine($"[yellow]Interactive Mode: {(interactive ? "ON" : "OFF")}[/]");
AnsiConsole.MarkupLine($"[yellow]Dry Run: {(dryRun ? "ON" : "OFF")}[/]");
AnsiConsole.WriteLine();

AnsiConsole.MarkupLine("[green]✓ Ready to scan and remediate[/]");
AnsiConsole.MarkupLine("[dim]Implementation in progress...[/]");

static string? ExtractArgument(string[] args, params string[] flags)
{
    for (int i = 0; i < args.Length; i++)
    {
        if (flags.Contains(args[i]) && i + 1 < args.Length)
        {
            return args[i + 1];
        }
    }
    return null;
}

