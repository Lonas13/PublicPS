# Load necessary assemblies for GUI components
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Add custom DataGridView Progress Bar Column
Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;
using System.ComponentModel;
using System.Drawing;

public class DataGridViewProgressBarCell : DataGridViewImageCell
{
    static Image emptyImage;
    static DataGridViewProgressBarCell()
    {
        emptyImage = new Bitmap(1, 1, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
    }

    public DataGridViewProgressBarCell()
    {
        this.ValueType = typeof(int);
    }

    // Method required to make the Progress Cell consistent with the default Image Cell.
    protected override object GetFormattedValue(
        object value,
        int rowIndex,
        ref DataGridViewCellStyle cellStyle,
        TypeConverter valueTypeConverter,
        TypeConverter formattedValueTypeConverter,
        DataGridViewDataErrorContexts context)
    {
        return emptyImage;
    }

    protected override void Paint(
        Graphics graphics,
        Rectangle clipBounds,
        Rectangle cellBounds,
        int rowIndex,
        DataGridViewElementStates cellState,
        object value,
        object formattedValue,
        string errorText,
        DataGridViewCellStyle cellStyle,
        DataGridViewAdvancedBorderStyle advancedBorderStyle,
        DataGridViewPaintParts paintParts)
    {
        int progressVal = 0;
        string statusText = "Pending";

        if (value != null)
        {
            if (value is int)
            {
                progressVal = (int)value;
            }
            else if (value is string)
            {
                statusText = value.ToString();
                int result;
                if (int.TryParse(statusText.TrimEnd('%'), out result))
                {
                    progressVal = result;
                }
                else
                {
                    progressVal = 0;
                }
            }
        }

        float percentage = ((float)progressVal / 100.0f);

        // Draw the background of the cell
        Brush backColorBrush = new SolidBrush(cellStyle.BackColor);
        graphics.FillRectangle(backColorBrush, cellBounds);

        // Draw the progress bar
        Rectangle progressBarArea = new Rectangle(cellBounds.X + 2, cellBounds.Y + 2,
            Convert.ToInt32((cellBounds.Width - 4) * percentage), cellBounds.Height - 4);

        Brush progressBarBrush = Brushes.Blue;
        if (progressVal >= 100)
        {
            progressBarBrush = Brushes.Green;
            statusText = "Completed";
        }
        else if (progressVal < 0)
        {
            progressBarBrush = Brushes.Red;
            statusText = "Error";
        }

        graphics.FillRectangle(progressBarBrush, progressBarArea);

        // Draw the cell border
        graphics.DrawRectangle(Pens.Black, new Rectangle(cellBounds.X, cellBounds.Y, cellBounds.Width - 1, cellBounds.Height - 1));

        // Draw the status text
        statusText = statusText ?? "";
        SizeF textSize = graphics.MeasureString(statusText, cellStyle.Font);
        PointF textLocation = new PointF(
            cellBounds.X + (cellBounds.Width - textSize.Width) / 2,
            cellBounds.Y + (cellBounds.Height - textSize.Height) / 2);
        Brush textBrush = new SolidBrush(Color.White);
        graphics.DrawString(statusText, cellStyle.Font, textBrush, textLocation);
    }
}

public class DataGridViewProgressBarColumn : DataGridViewImageColumn
{
    public DataGridViewProgressBarColumn()
    {
        this.CellTemplate = new DataGridViewProgressBarCell();
        this.ValueType = typeof(int);
    }
}
"@ -ReferencedAssemblies System.Windows.Forms.dll,System.Drawing.dll

# Function to get installed applications
function Get-InstalledApplications {
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
    )

    $applications = @()

    foreach ($registryPath in $registryPaths) {
        $subKeys = Get-ChildItem -Path $registryPath -ErrorAction SilentlyContinue
        foreach ($subKey in $subKeys) {
            $properties = Get-ItemProperty -Path $subKey.PSPath -ErrorAction SilentlyContinue
            $displayName = $properties.DisplayName
            $uninstallString = $properties.UninstallString

            if ($displayName -and $uninstallString) {
                $applications += [PSCustomObject]@{
                    Name = $displayName
                    UninstallString = $uninstallString
                }
            }
        }
    }
    return $applications
}

# Retrieve installed applications
$applications = Get-InstalledApplications

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Application Uninstaller"
$form.Size = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = "CenterScreen"

# Create a DataGridView to list applications
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Size = New-Object System.Drawing.Size(860, 500)
$dataGridView.Location = New-Object System.Drawing.Point(10, 10)
$dataGridView.AutoSizeColumnsMode = 'Fill'
$dataGridView.AllowUserToAddRows = $false
$dataGridView.RowHeadersVisible = $false
$dataGridView.SelectionMode = 'FullRowSelect'

# Add checkbox column
$checkboxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$checkboxColumn.HeaderText = ""
$checkboxColumn.Width = 30
$checkboxColumn.ReadOnly = $false
$dataGridView.Columns.Add($checkboxColumn)

# Add application name column
$nameColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$nameColumn.Name = "Name"
$nameColumn.HeaderText = "Application Name"
$nameColumn.ReadOnly = $true
$dataGridView.Columns.Add($nameColumn)

# Add uninstall string column
$uninstallColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$uninstallColumn.Name = "UninstallString"
$uninstallColumn.HeaderText = "Uninstall Command"
$uninstallColumn.ReadOnly = $true
$dataGridView.Columns.Add($uninstallColumn)

# Add progress bar column
$progressColumn = New-Object DataGridViewProgressBarColumn
$progressColumn.Name = "Progress"
$progressColumn.HeaderText = "Status"
$progressColumn.ReadOnly = $true
$dataGridView.Columns.Add($progressColumn)

# Populate the DataGridView with applications
foreach ($app in $applications) {
    $index = $dataGridView.Rows.Add()
    $dataGridView.Rows[$index].Cells[1].Value = $app.Name
    $dataGridView.Rows[$index].Cells[2].Value = $app.UninstallString
    $dataGridView.Rows[$index].Cells[3].Value = "Pending"
}

# Add the DataGridView to the form
$form.Controls.Add($dataGridView)

# Create a button to start uninstallation
$uninstallButton = New-Object System.Windows.Forms.Button
$uninstallButton.Location = New-Object System.Drawing.Point(10, 520)
$uninstallButton.Size = New-Object System.Drawing.Size(200, 30)
$uninstallButton.Text = "Uninstall Selected Applications"

# Add the button to the form
$form.Controls.Add($uninstallButton)

# Event handler for the uninstall button click
$uninstallButton.Add_Click({
    # Get selected applications
    $selectedRows = @()
    for ($i = 0; $i -lt $dataGridView.Rows.Count; $i++) {
        if ($dataGridView.Rows[$i].Cells[0].Value -eq $true) {
            $selectedRows += $dataGridView.Rows[$i]
        }
    }

    if ($selectedRows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one application to uninstall.", "No Applications Selected",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    # Disable the uninstall button during the process
    $uninstallButton.Enabled = $false
    $dataGridView.Enabled = $false

    # Uninstall selected applications
    foreach ($row in $selectedRows) {
        $appName = $row.Cells[1].Value
        $uninstallCommand = $row.Cells[2].Value

        # Update status to "Starting"
        $row.Cells[3].Value = "Starting"
        $dataGridView.Refresh()

        # Adjust command for silent uninstall and suppress reboot
        if ($uninstallCommand -match "MsiExec\.exe") {
            if ($uninstallCommand -notmatch "/qn") {
                $uninstallCommand += " /qn"
            }
            if ($uninstallCommand -notmatch "REBOOT=ReallySuppress") {
                $uninstallCommand += " REBOOT=ReallySuppress"
            }
        } else {
            if ($uninstallCommand -notmatch "/silent") {
                $uninstallCommand += " /silent"
            }
            if ($uninstallCommand -notmatch "/norestart") {
                $uninstallCommand += " /norestart"
            }
        }

        # Execute the uninstall command
        try {
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "cmd.exe"
            $processInfo.Arguments = "/c `"$uninstallCommand`""
            $processInfo.WindowStyle = "Hidden"
            $processInfo.CreateNoWindow = $true

            $process = [System.Diagnostics.Process]::Start($processInfo)

            # Update status to "Uninstalling..."
            $row.Cells[3].Value = "Uninstalling..."
            $dataGridView.Refresh()

            # Wait for the process to exit
            $process.WaitForExit()

            # Check exit code
            if ($process.ExitCode -eq 0) {
                $row.Cells[3].Value = "Completed"
            } else {
                $row.Cells[3].Value = "Failed"
            }
        } catch {
            $row.Cells[3].Value = "Error"
            [System.Windows.Forms.MessageBox]::Show("Failed to uninstall $appName.`nError: $_", "Uninstallation Error",
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } finally {
            # Refresh the DataGridView to update the progress bar
            $dataGridView.Refresh()
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Selected applications have been uninstalled.", "Uninstallation Complete",
        [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    # Close the form after uninstallation
    $form.Close()
})

# Show the form
[void]$form.ShowDialog()