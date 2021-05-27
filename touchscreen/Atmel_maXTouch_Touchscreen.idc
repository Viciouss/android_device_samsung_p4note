# Input device configuration file for a touch screen that supports pressure,
# size and orientation.  The pressure and size scale factors were obtained
# by measuring the characteristics of the device itself and deriving
# useful approximations based on the resolution of the touch sensor and the
# display.
#
# Note that these parameters are specific to a particular device model.
# Different parameters will need to be used for other devices.

device.internal = 1

# Basic Parameters
touch.deviceType = touchScreen
touch.orientationAware = 1

output.width = 1280
output.height = 800

# Size
# Based on empirical measurements, we estimate the size of the contact
# using size = sqrt(area) * 28 + 0.
touch.size.calibration = area
touch.size.scale = 28
touch.size.bias = 0
touch.size.isSummed = 0

# Pressure
# Driver reports signal strength as pressure.
#
# A normal index finger touch typically registers about 80 signal strength
# units although we don't expect these values to be accurate.
touch.pressure.calibration = amplitude
touch.pressure.scale = 0.0125

# Orientation
touch.orientation.calibration = vector