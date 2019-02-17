//
//  MRMediaRemote.h
//  Pock
//
//  Created by Pierluigi Galdi on 17/02/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

typedef void (^MRMediaRemoteGetNowPlayingInfoBlock)(NSDictionary *info);
typedef void (^MRMediaRemoteGetNowPlayingClientBlock)(id clientObj);
typedef void (^MRMediaRemoteGetNowPlayingApplicationIsPlayingBlock)(BOOL playing);

void MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t queue);
void MRMediaRemoteGetNowPlayingClient(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingClientBlock block);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoBlock block);
void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingApplicationIsPlayingBlock block);

extern NSString *MRNowPlayingClientGetBundleIdentifier(id clientObj);
extern NSString *MRNowPlayingClientGetParentAppBundleIdentifier(id clientObj);

extern NSString *kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification;
extern NSString *kMRMediaRemoteNowPlayingApplicationClientStateDidChange;
extern NSString *kMRNowPlayingPlaybackQueueChangedNotification;
extern NSString *kMRPlaybackQueueContentItemsChangedNotification;
extern NSString *kMRMediaRemoteNowPlayingApplicationDidChangeNotification;

extern NSString *kMRMediaRemoteNowPlayingInfoAlbum;
extern NSString *kMRMediaRemoteNowPlayingInfoArtist;
extern NSString *kMRMediaRemoteNowPlayingInfoTitle;

typedef enum {
    /*
     * Use nil for userInfo.
     */
    kMRPlay = 0,
    kMRPause = 1,
    kMRTogglePlayPause = 2,
    kMRStop = 3,
    kMRNextTrack = 4,
    kMRPreviousTrack = 5,
    kMRToggleShuffle = 6,
    kMRToggleRepeat = 7,
    kMRStartForwardSeek = 8,
    kMREndForwardSeek = 9,
    kMRStartBackwardSeek = 10,
    kMREndBackwardSeek = 11,
    kMRGoBackFifteenSeconds = 12,
    kMRSkipFifteenSeconds = 13,
    
    /*
     * Use a NSDictionary for userInfo, which contains three keys:
     * kMRMediaRemoteOptionTrackID
     * kMRMediaRemoteOptionStationID
     * kMRMediaRemoteOptionStationHash
     */
    kMRLikeTrack = 0x6A,
    kMRBanTrack = 0x6B,
    kMRAddTrackToWishList = 0x6C,
    kMRRemoveTrackFromWishList = 0x6D
} MRCommand;

extern Boolean MRMediaRemoteSendCommand(MRCommand command, id userInfo);
