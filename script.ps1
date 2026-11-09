Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$code = @"
using System;
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i(); int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int j(); int GetMasterVolumeLevelScalar(out float pfLevel); int k(); int l(); int m(); int n();
    int SetMute(bool bMute, Guid pguidEventContext); int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice { int Activate(ref Guid id, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object a); }
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator { int f(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint); }
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObject { }
public class Audio {
    static IAudioEndpointVolume Vol() {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null; enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
        Guid iid = typeof(IAudioEndpointVolume).GUID; object o;
        dev.Activate(ref iid, 1, IntPtr.Zero, out o); return (IAudioEndpointVolume)o;
    }
    public static float GetVolume() { float v; Vol().GetMasterVolumeLevelScalar(out v); return v; }
    public static void SetVolume(float volume) { Vol().SetMasterVolumeLevelScalar(volume, Guid.Empty); }
}
"@
Add-Type -TypeDefinition $code -Language CSharp

function Show-VolumePopup {
    if ($global:PopupForm -ne $null -and -not $global:PopupForm.IsDisposed) {
        $global:PopupForm.Close()
        return
    }
    $global:PopupForm = New-Object System.Windows.Forms.Form
    $global:PopupForm.Text = "RockFM Volume"
    $global:PopupForm.Size = New-Object System.Drawing.Size(250, 100)
    $global:PopupForm.StartPosition = "CenterScreen"
    $global:PopupForm.TopMost = $true
    $global:PopupForm.FormBorderStyle = "FixedToolWindow"
    $global:PopupForm.ShowInTaskbar = $false

    $trackBar = New-Object System.Windows.Forms.TrackBar
    $trackBar.Minimum = 0; $trackBar.Maximum = 100
    $currentVol = [Audio]::GetVolume()
    $trackBar.Value = [math]::Round($currentVol * 100)
    $trackBar.Location = New-Object System.Drawing.Point(20, 10)
    $trackBar.Width = 200; $trackBar.TickFrequency = 10
    $trackBar.add_Scroll({ [Audio]::SetVolume($trackBar.Value / 100.0) })

    $global:PopupForm.add_KeyDown({ param($sender, $e) if ($e.KeyCode -eq "Escape") { $global:PopupForm.Close() } })
    $global:FocusTimer = New-Object System.Windows.Forms.Timer
    $global:FocusTimer.Interval = 100
    $global:FocusTimer.add_Tick({
        if ($global:PopupForm -ne $null -and -not $global:PopupForm.IsDisposed) {
            if (-not $global:PopupForm.ContainsFocus) { $global:FocusTimer.Stop(); $global:PopupForm.Close() }
        }
    })
    $global:PopupForm.Add_Shown({ $global:PopupForm.Activate(); $global:FocusTimer.Start() })
    $global:PopupForm.Add_FormClosed({ $global:FocusTimer.Stop(); $global:FocusTimer.Dispose() })
    $global:PopupForm.Controls.Add($trackBar)
    $global:PopupForm.Show()
}

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$notifyIcon.Text = "RockFM Radio"
$notifyIcon.Visible = $true
$notifyIcon.add_MouseClick({ param($sender, $e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Show-VolumePopup } })

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Выход")
$exitItem.add_Click({
    Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "headless" } | Stop-Process -Force -ErrorAction SilentlyContinue
    $notifyIcon.Visible = $false; $notifyIcon.Dispose(); [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($exitItem)
$notifyIcon.ContextMenuStrip = $contextMenu
[System.Windows.Forms.Application]::Run()
