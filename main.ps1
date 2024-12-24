# ADS TOOL
Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,System.Windows.Forms

$x=@"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ADS Finder" Height="500" Width="650"
    WindowStartupLocation="CenterScreen" WindowStyle="SingleBorderWindow">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,10">
            <Label Content="Target Folder:" VerticalAlignment="Center"/>
            <TextBox x:Name="rSwHqZ" Width="350" Margin="5,0,5,0"/>
            <Button x:Name="kaZhLB" Content="Browse..." Width="80" Margin="0,0,5,0"/>
        </StackPanel>
        <Button x:Name="qNtOiL" Content="Scan for ADS" Grid.Row="1" Width="110" HorizontalAlignment="Left" Margin="0,0,0,10"/>
        <StackPanel Orientation="Horizontal" Grid.Row="2">
            <ProgressBar x:Name="wDnJAY" Width="400" Height="20" Margin="0,0,10,0" Visibility="Collapsed"/>
            <TextBlock x:Name="HzQdAC" VerticalAlignment="Center" Visibility="Collapsed"/>
        </StackPanel>
        <DataGrid x:Name="FhDpXe" Grid.Row="3" AutoGenerateColumns="False" IsReadOnly="True" Margin="0,10,0,0">
            <DataGrid.Columns>
                <DataGridTextColumn Header="File Path" Binding="{Binding FilePath}" Width="3*"/>
                <DataGridTextColumn Header="Stream Name" Binding="{Binding StreamName}" Width="2*"/>
                <DataGridTextColumn Header="Length" Binding="{Binding Length}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@
$W=[System.Windows.Markup.XamlReader]::Parse($x)

function BFS { param($T)
  $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
  if($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$T.Text=$dlg.SelectedPath}
}

function SFA {
  param($D,[System.Windows.Controls.ProgressBar]$P,[System.Windows.Controls.TextBlock]$L)
  if([string]::IsNullOrWhiteSpace($D) -or !(Test-Path $D -PathType Container)){return @()}
  $skip='C:\Windows','C:\Program Files','C:\Program Files (x86)','C:\ProgramData','C:\System Volume Information','C:\Recovery','C:\Users\All Users'|%{$_.ToLower()}
  $res=New-Object System.Collections.Generic.List[Object]
  $all=Get-ChildItem $D -Recurse -Force -File -EA SilentlyContinue
  $cnt=$all.Count;if($cnt -eq 0){return}
  $P.Maximum=$cnt;$P.Value=0;$L.Text="0 / $cnt";$P.Visibility='Visible';$L.Visibility='Visible'
  $i=0
  foreach($f in $all){
    $i++;$P.Value=$i;$L.Text="$i / $cnt"
    [System.Windows.Forms.Application]::DoEvents()|Out-Null
    if($skip -contains (Split-Path $f.FullName -Parent).ToLower()){continue}
    try{
      (Get-Item $f.FullName -Stream * -EA Stop|?{$_.Stream -ne '::$DATA'})|%{
        $obj=[PSCustomObject]@{FilePath=$f.FullName;StreamName=$_.Stream;Length=$_.Length}
        $res.Add($obj)|Out-Null
      }
    }catch{}
  }
  $P.Visibility='Collapsed';$L.Visibility='Collapsed'
  $res
}

[System.Threading.Thread]::CurrentThread.ApartmentState=[System.Threading.ApartmentState]::STA

$tx=$W.FindName('rSwHqZ');$br=$W.FindName('kaZhLB');$sc=$W.FindName('qNtOiL')
$gd=$W.FindName('FhDpXe');$pb=$W.FindName('wDnJAY');$lb=$W.FindName('HzQdAC')

$br.Add_Click({BFS $tx})
$sc.Add_Click({
  $gd.ItemsSource=$null
  $r=SFA $tx.Text $pb $lb
  if($r -and $r.Count -gt 0){$gd.ItemsSource=$r}else{[System.Windows.MessageBox]::Show('No ADS found or invalid directory.')}
})
$W.ShowDialog()|Out-Null 
