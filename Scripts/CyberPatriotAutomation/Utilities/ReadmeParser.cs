namespace CyberPatriotAutomation.Utilities;

/// <summary>
/// Parses README files to extract task requirements
/// </summary>
public class ReadmeParser
{
    /// <summary>
    /// Read and parse README file for task information
    /// </summary>
    public static async Task<Dictionary<string, string>> ParseReadmeAsync(string filePath)
    {
        var tasks = new Dictionary<string, string>();

        try
        {
            if (!File.Exists(filePath))
                return tasks;

            var content = await File.ReadAllTextAsync(filePath);
            var lines = content.Split(new[] { Environment.NewLine }, StringSplitOptions.None);

            string? currentTask = null;
            var description = new List<string>();

            foreach (var line in lines)
            {
                // Check for task headers (typically marked with # or similar)
                if (line.StartsWith("#") || line.StartsWith("##"))
                {
                    if (currentTask != null && description.Count > 0)
                        tasks[currentTask] = string.Join(" ", description).Trim();

                    currentTask = line.TrimStart('#').Trim();
                    description.Clear();
                }
                else if (!string.IsNullOrWhiteSpace(line) && currentTask != null)
                {
                    description.Add(line.Trim());
                }
            }

            // Add last task
            if (currentTask != null && description.Count > 0)
                tasks[currentTask] = string.Join(" ", description).Trim();

            return tasks;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error parsing README: {ex.Message}");
            return tasks;
        }
    }
}
