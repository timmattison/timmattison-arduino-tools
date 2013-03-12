#!/usr/bin/env perl

# convert-to-grove-96x96-oled-grayscale-image.pl 
#
# This script converts an image (using ImageMagick) to an array that can be incorporated
#   into an Arduino sketch using the GROVE 96x96 OLED.  The output array is a chunk of
#   code that displays a grayscale image.
#
# This module is available here: http://www.epictinker.com/Grove-OLED-96x96-p/ole42178p.htm
# Tech docs are available here:  http://www.seeedstudio.com/wiki/Grove_-_OLED_Display_96*96

my $X_SIZE = 96;
my $Y_SIZE = 96;

# Load ImageMagick
use Image::Magick;

# Get the filename
my $filename = $ARGV[0];

# Make sure they specified it
if(!defined($filename)) {
  die "You must specify a file name";
}

# Make sure the file exists
if(! -e $filename) {
  die "$filename does not exist";
}

# Create a new ImageMagick object
$image = new Image::Magick;

# Load the image
$image->Read($filename);

my $imageXSize = $image->Get('width');
my $imageYSize = $image->Get('height');

# Is the image the right size?
if(($imageXSize != $X_SIZE) || ($imageYSize != $Y_SIZE)) {
  # No, scale it.  This can be ugly if you don't use a square image.
  print "Resizing from $imageXSize, $imageYSize to $X_SIZE, $Y_SIZE\n";
  $image->Resize("Geometry=>'$X_SIZE,$Y_SIZE'");
}

# Create the output text array
my $output = "";
$output = <<END;
#include <Wire.h>
#include <SeeedGrayOLED.h>
#include <avr/pgmspace.h>

void loop()
{
}

void setup()
{
  Wire.begin();	
  SeeedGrayOled.init();
  SeeedGrayOled.clearDisplay();
  SeeedGrayOled.setHorizontalMode();

END

# Create a temporary space for the binary values we accumulate
my $binary_output_value = 0;
my $counter = 0;

# Loop through all of the pixels
for(my $x = 0; $x < $X_SIZE; $x++) {
  for(my $y = 0; $y < $Y_SIZE; $y++) {
    # Get the pixel
    my $pixel_location = "pixel[" . $y . "," . $x . "]";
    my $pixel_data = $image->Get($pixel_location);

    # Get the RGBA data
    my ($r, $g, $b, $a) = split(",", $pixel_data);

    # Convert it to a gray value
    my $gray = ($r + $g + $b) / 3;

    # Convert that gray value to grayscale
    $binary_output_value = $binary_output_value | (($gray / 4096) & 0xF) << ((1 - $counter) * 4);
    $counter++;

    if($counter == 2) {
      # Print out the hex value for it
      $output .= "  SeeedGrayOled.sendData(0x" . sprintf("%02x", $binary_output_value) . ");\n";

      $counter = 0;
      $binary_output_value = 0;
    }
  }
}

# Close the setup function
$output .= <<END;
  SeeedGrayOled.setHorizontalMode();
}
END

# Print it out
print $output;
