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

/*
 GOAL
 This is a category of NSSound build using CoreAudio to get and set the volume of the
 system sound and some other utility.
 It was implemented using the Apple documentation and various unattributed code fragments
 found on the net. For this reason, its use is free for all.
 
 USE
 To maintain the Cocoa conventions, a property-like syntax was used; the following
 methods ("properties") are available:
 
	(float)systemVolume			- return the volume of the default sound device
	setSystemVolume(float)			- set the volume of the default sound device
	(AudioDeviceID)defaultOutputDevice	- return the default output device
	applyMute(boolean)			- enable or disable muting, if supported
 
 REQUIREMENTS
 At least MacOS X 10.6
 Core Audio Framework
 */

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioServices.h>

@interface NSSound (ISSoundAdditions)

+ (AudioDeviceID)defaultOutputDevice;

+ (float)systemVolume;
+ (void)setSystemVolume:(float)inVolume;

+ (void)increaseSystemVolumeBy:(float)amount;
+ (void)decreaseSystemVolumeBy:(float)amount;

+ (void)applyMute:(Boolean)m;
+ (Boolean)isMuted;

#define	THRESHOLD	0.005			//if the volume should be set under this value, the device will be muted

@end
