# Modern folder picker (IFileDialog COM via CoCreateInstance)
# Falls back to legacy FolderBrowserDialog on failure.
# Output: folder path or "CANCELLED"

try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class FolderPicker {
    [DllImport("ole32.dll")]
    static extern int CoCreateInstance(
        ref Guid clsid, IntPtr outer, uint ctx, ref Guid iid, out IntPtr ppv);

    public static string Pick(string title) {
        var clsid = new Guid("DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7");
        var iid   = new Guid("42F85136-DB7E-439C-85F1-E4075D135FC8");
        IntPtr ptr;
        CoCreateInstance(ref clsid, IntPtr.Zero, 1, ref iid, out ptr);
        if (ptr == IntPtr.Zero) return "CANCELLED";

        var dlg = (IFileOpenDialog)Marshal.GetObjectForIUnknown(ptr);
        uint opt;
        dlg.GetOptions(out opt);
        dlg.SetOptions(opt | 0x20);  // FOS_PICKFOLDERS
        dlg.SetTitle(title);

        if (dlg.Show(IntPtr.Zero) != 0) {
            Marshal.Release(ptr);
            return "CANCELLED";
        }

        IShellItem item;
        dlg.GetResult(out item);
        string path;
        item.GetDisplayName(0x80058000, out path);  // SIGDN_FILESYSPATH
        Marshal.Release(ptr);
        return path;
    }
}

[ComImport, Guid("42F85136-DB7E-439C-85F1-E4075D135FC8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IFileOpenDialog {
    [PreserveSig] int Show(IntPtr parent);
    void SetFileTypes(uint c, IntPtr f);
    void SetFileTypeIndex(uint i);
    void GetFileTypeIndex(out uint i);
    void Advise(IntPtr p, out uint c);
    void Unadvise(uint c);
    void SetOptions(uint o);
    void GetOptions(out uint o);
    void SetDefaultFolder(IShellItem i);
    void SetFolder(IShellItem i);
    void GetFolder(out IShellItem i);
    void GetCurrentSelection(out IShellItem i);
    void SetFileName([MarshalAs(UnmanagedType.LPWStr)] string n);
    void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string n);
    void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string t);
    void SetOkButtonLabel([MarshalAs(UnmanagedType.LPWStr)] string t);
    void SetFileNameLabel([MarshalAs(UnmanagedType.LPWStr)] string t);
    void GetResult(out IShellItem i);
}

[ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IShellItem {
    void BindToHandler(IntPtr p, ref Guid b, ref Guid r, out IntPtr v);
    void GetParent(out IShellItem i);
    void GetDisplayName(uint s, [MarshalAs(UnmanagedType.LPWStr)] out string n);
    void GetAttributes(uint m, out uint a);
    void Compare(IShellItem i, uint h, out int o);
}
"@ -ErrorAction Stop

    Write-Output ([FolderPicker]::Pick("Select game project folder"))
} catch {
    # Fallback: legacy dialog
    Add-Type -AssemblyName System.Windows.Forms
    $f = New-Object System.Windows.Forms.FolderBrowserDialog
    $f.Description = "Select game project folder"
    $f.ShowNewFolderButton = $true
    if ($f.ShowDialog() -eq "OK") { Write-Output $f.SelectedPath } else { Write-Output "CANCELLED" }
}
