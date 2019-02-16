//
//  ISSoundAdditions.m (ver 1.2 - 2012.10.27)
//
//	Created by Massimo Moiso (2012-09) InerziaSoft
//	based on an idea of Antonio Nunes, SintraWorks
//
// Permission is granted free of charge to use this code without restriction
// and without limitation, with the only condition that the copyright
// notice and this permission shall be included in all copies.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "ISSoundAdditions.h"

AudioDeviceID obtainDefaultOutputDevice(void);

@implementation NSSound (ISSoundAdditions)

//
//	Return the ID of the default audio device; this is a C routine
//
//	IN:		none
//	OUT:	the ID of the default device or AudioObjectUnknown
//
AudioDeviceID obtainDefaultOutputDevice()
{
    AudioDeviceID theAnswer = kAudioObjectUnknown;
    UInt32 theSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress theAddress;
	
	theAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
	theAddress.mScope = kAudioObjectPropertyScopeGlobal;
	theAddress.mElement = kAudioObjectPropertyElementMaster;
	
	//first be sure that a default device exists
	if (! AudioObjectHasProperty(kAudioObjectSystemObject, &theAddress) )	{
		NSLog(@"Unable to get default audio device");
		return theAnswer;
	}
	//get the property 'default output device'
    OSStatus theError = AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &theSize, &theAnswer);
    if (theError != noErr) {
		NSLog(@"Unable to get output audio device");
		return theAnswer;
	}
    return theAnswer;
}

//
//	Return the ID of the default audio device; this is a category class method
//	that can be called from outside
//
//	IN:		none
//	OUT:	the ID of the default device or AudioObjectUnknown
//
+ (AudioDeviceID)defaultOutputDevice
{
	return obtainDefaultOutputDevice();
}


//
//	Return the system sound volume as a float in the range [0...1]
//
//	IN:		none
//	OUT:	(float) the volume of the default device
//
+ (float)systemVolume
{	
	AudioDeviceID				defaultDevID = kAudioObjectUnknown;
	UInt32						theSize = sizeof(Float32);
	OSStatus					theError;
	Float32						theVolume = 0;
	AudioObjectPropertyAddress	theAddress;
	
	defaultDevID = obtainDefaultOutputDevice();
	if (defaultDevID == kAudioObjectUnknown) return 0.0;		//device not found: return 0
	
	theAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
	theAddress.mScope = kAudioDevicePropertyScopeOutput;
	theAddress.mElement = kAudioObjectPropertyElementMaster;
	
	//be sure that the default device has the volume property
	if (! AudioObjectHasProperty(defaultDevID, &theAddress) ) {
		NSLog(@"No volume control for device 0x%0x",defaultDevID);
		return 0.0;
	}
	
	//now read the property and correct it, if outside [0...1]
	theError = AudioObjectGetPropertyData(defaultDevID, &theAddress, 0, NULL, &theSize, &theVolume);
	if ( theError != noErr )	{
		NSLog(@"Unable to read volume for device 0x%0x", defaultDevID);
		return 0.0;
	}
	theVolume = theVolume > 1.0 ? 1.0 : (theVolume < 0.0 ? 0.0 : theVolume);
	
	return theVolume;
}

//
//	Set the volume of the default device
//
//	IN:		(float)the new volume
//	OUT:	none
//
+ (void)setSystemVolume:(float)theVolume
{
	float						newValue = theVolume;
	AudioObjectPropertyAddress	theAddress;
	AudioDeviceID				defaultDevID;
	OSStatus					theError = noErr;
	UInt32						muted;
	Boolean						canSetVol = YES, muteValue;
	Boolean						hasMute = YES, canMute = YES;
	
	defaultDevID = obtainDefaultOutputDevice();
	if (defaultDevID == kAudioObjectUnknown) {			//device not found: return without trying to set
		NSLog(@"Device unknown");
		return;
	}
	
		//check if the new value is in the correct range - normalize it if not
	newValue = theVolume > 1.0 ? 1.0 : (theVolume < 0.0 ? 0.0 : theVolume);
	if (newValue != theVolume) {
		NSLog(@"Tentative volume (%5.2f) was out of range; reset to %5.2f", theVolume, newValue);
	}
	
	theAddress.mElement = kAudioObjectPropertyElementMaster;
	theAddress.mScope = kAudioDevicePropertyScopeOutput;
	
		//set the selector to mute or not by checking if under threshold and check if a mute command is available
	if ( (muteValue = (newValue < THRESHOLD)) )
	{
		theAddress.mSelector = kAudioDevicePropertyMute;
		hasMute = AudioObjectHasProperty(defaultDevID, &theAddress);
		if (hasMute)
		{
			theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute);
			if (theError != noErr || !canMute)
			{
				canMute = NO;
				NSLog(@"Should mute device 0x%0x but did not success",defaultDevID);
			}
		}
		else canMute = NO;
	}
	else
	{
		theAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
	}
	
// **** now manage the volume following the what we found ****
	
		//be sure the device has a volume command
	if (! AudioObjectHasProperty(defaultDevID, &theAddress))
	{
		NSLog(@"The device 0x%0x does not have a volume to set", defaultDevID);
		return;
	}
	
		//be sure the device can set the volume
	theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canSetVol);
	if ( theError!=noErr || !canSetVol )
	{
		NSLog(@"The volume of device 0x%0x cannot be set", defaultDevID);
		return;
	}
	
		//if under the threshold then mute it, only if possible - done/exit
	if (muteValue && hasMute && canMute)
	{
		muted = 1;
		theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, NULL, sizeof(muted), &muted);
		if (theError != noErr)
		{
			NSLog(@"The device 0x%0x was not muted",defaultDevID);
			return;
		}
	}
	else		//else set it
	{
		theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, NULL, sizeof(newValue), &newValue);
		if (theError != noErr)
		{
			NSLog(@"The device 0x%0x was unable to set volume", defaultDevID);
		}
			//if device is able to handle muting, maybe it was muted, so unlock it
		if (hasMute && canMute)
		{
			theAddress.mSelector = kAudioDevicePropertyMute;
			muted = 0;
			theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, NULL, sizeof(muted), &muted);
		}
	}
	if (theError != noErr) {
		NSLog(@"Unable to set volume for device 0x%0x", defaultDevID);
	}
}


//
//	Increase the volume of the system device by a certain value
//
//	IN:		(float) amount of volume to increase
//	OUT:	none
//
+ (void)increaseSystemVolumeBy:(float)amount {
    [self setSystemVolume:self.systemVolume+amount];
}

//
//	Decrease the volume of the system device by a certain value
//
//	IN:		(float) amount of volume to decrease
//	OUT:	none
//
+ (void)decreaseSystemVolumeBy:(float)amount {
    [self setSystemVolume:self.systemVolume-amount];
}

//
//	IN:		(Boolean) if true the device is muted, false it is unmated
//	OUT:		none
//
+ (void)applyMute:(Boolean)m
{
	AudioDeviceID				defaultDevID = kAudioObjectUnknown;
	AudioObjectPropertyAddress	theAddress;
	Boolean						hasMute, canMute = YES;
	OSStatus					theError = noErr;
	UInt32						muted = 0;
	
	defaultDevID = obtainDefaultOutputDevice();
	if (defaultDevID == kAudioObjectUnknown) {			//device not found
		NSLog(@"Device unknown");
		return;
	}
	
	theAddress.mElement = kAudioObjectPropertyElementMaster;
	theAddress.mScope = kAudioDevicePropertyScopeOutput;
	theAddress.mSelector = kAudioDevicePropertyMute;
	muted = m ? 1 : 0;
	
	hasMute = AudioObjectHasProperty(defaultDevID, &theAddress);
	
	if (hasMute)
	{
		theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute);
		if (theError == noErr && canMute)
		{
			theError = AudioObjectSetPropertyData(defaultDevID, &theAddress, 0, NULL, sizeof(muted), &muted);
			if (theError != noErr) NSLog(@"Cannot change mute status of device 0x%0x", defaultDevID);
		}
	}
}

+ (Boolean)isMuted
{
    AudioDeviceID				defaultDevID = kAudioObjectUnknown;
    AudioObjectPropertyAddress	theAddress;
    Boolean						hasMute, canMute = YES;
    OSStatus					theError = noErr;
    UInt32						muted = 0;
    UInt32                      mutedSize = 4;
    
    defaultDevID = obtainDefaultOutputDevice();
    if (defaultDevID == kAudioObjectUnknown) {			//device not found
        NSLog(@"Device unknown");
        return false;           // works, but not the best return code for this
    }
    
    theAddress.mElement = kAudioObjectPropertyElementMaster;
    theAddress.mScope = kAudioDevicePropertyScopeOutput;
    theAddress.mSelector = kAudioDevicePropertyMute;
    
    hasMute = AudioObjectHasProperty(defaultDevID, &theAddress);
    
    if (hasMute)
    {
        theError = AudioObjectIsPropertySettable(defaultDevID, &theAddress, &canMute);
        if (theError == noErr && canMute)
        {
            theError = AudioObjectGetPropertyData(defaultDevID, &theAddress, 0, NULL, &mutedSize, &muted);
            if (muted) {
                return true;
            }
        }
    }
    return false;
}



@end
