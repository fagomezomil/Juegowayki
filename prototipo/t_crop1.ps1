Add-Type -AssemblyName System.Drawing
function Crop($in,$out,$y,$h){
  $img=[System.Drawing.Image]::FromFile($in)
  $w=$img.Width
  $rect=New-Object System.Drawing.Rectangle(0,$y,$w,$h)
  $bmp=New-Object System.Drawing.Bitmap($w,$h)
  $g=[System.Drawing.Graphics]::FromImage($bmp)
  $g.DrawImage($img,(New-Object System.Drawing.Rectangle(0,0,$w,$h)),$rect,[System.Drawing.GraphicsUnit]::Pixel)
  $bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose();$bmp.Dispose();$img.Dispose()
}
Crop "C:\Users\usuario\Proyectos\juego\prototipo\h_mapas.png" "C:\Users\usuario\Proyectos\juego\prototipo\z_mapas.png" 950 1100
Write-Output "done"