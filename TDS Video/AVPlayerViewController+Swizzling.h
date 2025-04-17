//
//  AVPlayerViewController+Swizzling.h
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

#ifndef AVPlayerViewController_Swizzling_h
#define AVPlayerViewController_Swizzling_h

#import <AVKit/AVKit.h>

@interface AVPlayer (Swizzling)

-(void)increaseVolume:(id)arg1 ;

@end





@interface AVPlayerViewController (Swizzling)

- (void)my_custom_viewDidLoad;
- (void)my_custom_viewDidAppear:(BOOL)animated;

@property (assign,getter=isPlayingOnSecondScreen,nonatomic) BOOL playingOnSecondScreen;
@property (nonatomic,readonly) BOOL usesExternalPlaybackWhileExternalScreenIsActive;

@property (nonatomic,readonly) CGSize maximumVideoResolution;

@property (assign,nonatomic) BOOL handlesAudioSessionInterruptions;
@property (getter=isPlayingOnMatchPointDevice,nonatomic,readonly) BOOL playingOnMatchPointDevice;
@property (nonatomic,readonly) BOOL hasReadableTimecodes;
@property (assign,getter=isAtMaxTime,nonatomic) BOOL atMaxTime;                                                      //@synthesize atMaxTime=_atMaxTime - In the implementation block
@property (assign,getter=isAtMinTime,nonatomic) BOOL atMinTime;                                                      //@synthesize atMinTime=_atMinTime - In the implementation block
@property (assign,getter=isScrubbing,nonatomic) BOOL scrubbing;                                                      //@synthesize scrubbing=_scrubbing - In the implementation block
@property (nonatomic,retain) AVPlayer * player;                                                                      //@synthesize player=_player - In the implementation block
@property (nonatomic,retain) AVPlayer * activePlayer;                                                                //@synthesize activePlayer=_activePlayer - In the implementation block
@property (assign,nonatomic) double activeRate;                                                                      //@synthesize activeRate=_activeRate - In the implementation block block
@property (assign,nonatomic) CGSize presentationSize;                                                                //@synthesize presentationSize=_presentationSize - In the implementation block
@property (nonatomic,retain) AVAsset * currentAssetIfReady;                                                          //@synthesize currentAssetIfReady=_currentAssetIfReady - In the implementation block

@property (nonatomic,retain) AVAsset * assetBeingPrepared;                                                           //@synthesize assetBeingPrepared=_assetBeingPrepared - In the implementation block
@property (assign,getter=isPictureInPictureSupported,nonatomic) BOOL pictureInPictureSupported;                      //@synthesize pictureInPictureSupported=_pictureInPictureSupported - In the implementation block
@property (nonatomic,retain) NSString * externalPlaybackAirPlayDeviceLocalizedName;                                  //@synthesize externalPlaybackAirPlayDeviceLocalizedName=_externalPlaybackAirPlayDeviceLocalizedName - In the implementation block

@property (getter=isReadyToPlay,nonatomic,readonly) BOOL readyToPlay;


@property (nonatomic,retain) AVAssetTrack * currentAudioTrack;                                                       //@synthesize currentAudioTrack=_currentAudioTrack - In the implementation block
@property (nonatomic,retain) AVAssetTrack * currentVideoTrack;                                                       //@synthesize currentVideoTrack=_currentVideoTrack - In the implementation block
@property (getter=isSeekingInternal) BOOL seekingInternal;                                                           //@synthesize seekingInternal=_seekingInternal - In the implementation block
@property (assign,getter=isSeeking,nonatomic) BOOL seeking;                                                          //@synthesize seeking=_seeking - In the implementation block
@property (assign,nonatomic) double seekToTime;                                                                      //@synthesize seekToTime=_seekToTime - In the implementation block
@property (assign,nonatomic) double initialScrubbingTime;                                                            //@synthesize initialScrubbingTime=_initialScrubbingTime - In the implementation block
@property (nonatomic,retain) NSDictionary * metadata;                                                                //@synthesize metadata=_metadata - In the implementation block
@property (nonatomic,retain) NSArray * contentChapters;                                                              //@synthesize contentChapters=_contentChapters - In the implementation block
@property (assign,getter=isComposable,nonatomic) BOOL composable;                                                    //@synthesize composable=_composable - In the implementation block
@property (assign,nonatomic) BOOL hasProtectedContent;                                                               //@synthesize hasProtectedContent=_hasProtectedContent - In the implementation block
@property (nonatomic,retain) NSArray * availableMetadataFormats;                                                     //@synthesize availableMetadataFormats=_availableMetadataFormats - In the implementation block
@property (assign,getter=isCompatibleWithAirPlayVideo,nonatomic) BOOL compatibleWithAirPlayVideo;                    //@synthesize compatibleWithAirPlayVideo=_compatibleWithAirPlayVideo - In the implementation block
@property (assign,nonatomic) double rateBeforeScrubBegan;                                                            //@synthesize rateBeforeScrubBegan=_rateBeforeScrubBegan - In the implementation block
@property (nonatomic,retain) AVCoordinatedPlaybackSuspension * scrubCoordinatorSuspension;                           //@synthesize scrubCoordinatorSuspension=_scrubCoordinatorSuspension - In the implementation block
@property (assign,getter=isPreventingIdleSystemSleep,nonatomic) BOOL preventingIdleSystemSleep;                      //@synthesize preventingIdleSystemSleep=_preventingIdleSystemSleep - In the implementation block
@property (assign,getter=isPreventingIdleDisplaySleep,nonatomic) BOOL preventingIdleDisplaySleep;                    //@synthesize preventingIdleDisplaySleep=_preventingIdleDisplaySleep - In the implementation block
@property (assign,getter=isDisablingAutomaticTermination,nonatomic) BOOL disablingAutomaticTermination;              //@synthesize disablingAutomaticTermination=_disablingAutomaticTermination - In the implementation block
@property (assign,nonatomic) BOOL allowsPictureInPicturePlayback;                                                    //@synthesize allowsPictureInPicturePlayback=_allowsPictureInPicturePlayback - In the implementation block
@property (assign,getter=isPictureInPictureActive,nonatomic) BOOL pictureInPictureActive;                            //@synthesize pictureInPictureActive=_pictureInPictureActive - In the implementation block
@property (assign,nonatomic) BOOL canTogglePictureInPicture;                                                         //@synthesize canTogglePictureInPicture=_canTogglePictureInPicture - In the implementation block
@property (nonatomic,copy) NSString * pipActivitySessionIdentifier;                                                  //@synthesize pipActivitySessionIdentifier=_pipActivitySessionIdentifier - In the implementation block
@property (assign,nonatomic) BOOL hasBegunInspection;                                                                //@synthesize hasBegunInspection=_hasBegunInspection - In the implementation block

@property (nonatomic,readonly) NSDate * currentDate;
@property (nonatomic,readonly) NSDate * currentOrEstimatedDate;

@property (assign,nonatomic) BOOL touchBarRequiresLinearPlayback;

@property (assign,nonatomic) BOOL shouldLoadVisualMediaSelectionOptions;                                             //@synthesize shouldLoadVisualMediaSelectionOptions=_shouldLoadVisualMediaSelectionOptions - In the implementation block
@property (nonatomic,readonly) NSArray * visualMediaSelectionOptions;
@property (assign,nonatomic) long long captionAppearanceDisplayType;                                                 //@synthesize captionAppearanceDisplayType=_captionAppearanceDisplayType - In the implementation block
@property (nonatomic,retain) AVMediaSelectionOption * currentVideoMediaSelectionOption;
@property (getter=isPlaybackSuspended,nonatomic,readonly) BOOL playbackSuspended;                                    //@synthesize playbackSuspended=_playbackSuspended - In the implementation block
@property (nonatomic,readonly) double suspendedRate;                                                                 //@synthesize suspendedRate=_suspendedRate - In the implementation block
@property (assign,nonatomic) BOOL coordinatedPlaybackActive;                                                         //@synthesize coordinatedPlaybackActive=_coordinatedPlaybackActive - In the implementation block
@property (nonatomic,readonly) long long status;
@property (nonatomic,readonly) NSError * error;
+(void)initialize;
+(id)keyPathsForValuesAffectingHasTrimmableContent;
+(id)keyPathsForValuesAffectingCanSeekChapterForward;
+(id)keyPathsForValuesAffectingCanSeek;
+(id)keyPathsForValuesAffectingCanSeekToEnd;
+(id)keyPathsForValuesAffectingSeekableTimeRanges;
+(id)keyPathsForValuesAffectingDefaultPlaybackRate;
+(id)keyPathsForValuesAffectingHasContent;
+(id)keyPathsForValuesAffectingPreferredDisplayCriteria;
+(id)keyPathsForValuesAffectingpreferredTransform;
+(id)keyPathsForValuesAffectingCanSeekToBeginning;
+(id)keyPathsForValuesAffectingReversePlaybackEndTime;
+(id)keyPathsForValuesAffectingPlaying;
+(id)keyPathsForValuesAffectingRate;
+(id)canonicalLanguageIdentifierFromString:(id)arg1 ;
+(id)keyPathsForValuesAffectingHasMediaSelectionOptions;
+(id)keyPathsForValuesAffectingContentDurationWithinEndTimes;
+(id)keyPathsForValuesAffectingPlayableOffline;
+(id)keyPathsForValuesAffectingPictureInPicturePossible;
+(id)keyPathsForValuesAffectingStreaming;
+(id)keyPathsForValuesAffectingCompletelySeekable;
+(id)keyPathsForValuesAffectingCanScanBackward;
+(id)keyPathsForValuesAffectingCurrentLegibleMediaSelectionOption;
+(id)keyPathsForValuesAffectingHasContentChapters;
+(id)keyPathsForValuesAffectingCurrentTimeWithinEndTimes;
+(id)keyPathsForValuesAffectingCurrentAudioMediaSelectionOption;
+(id)keyPathsForValuesAffectingReadyToPlay;
+(id)keyPathsForValuesAffectingVolume;
+(id)keyPathsForValuesAffectingCurrentVideoMediaSelectionOption;
+(id)keyPathsForValuesAffectingCanPause;
+(id)keyPathsForValuesAffectingHasEnabledAudio;
+(id)keyPathsForValuesAffectingMinTime;
+(id)keyPathsForValuesAffectingContentDimensions;
+(id)keyPathsForValuesAffectingMaxTime;
+(id)keyPathsForValuesAffectingMaximumVideoResolution;
+(id)keyPathsForValuesAffectingExternalPlaybackActive;
+(id)keyPathsForValuesAffectingStatus;
+(id)keyPathsForValuesAffectingHasAudioMediaSelectionOptions;
+(BOOL)cachedIsPictureInPictureSupported;
+(id)keyPathsForValuesAffectingCanSeekFrameForward;
+(id)keyPathsForValuesAffectingTimeControlStatus;
+(id)keyPathsForValuesAffectingActiveRate;
+(id)keyPathsForValuesAffectingHasLegibleMediaSelectionOptions;
+(id)keyPathsForValuesAffectingForwardPlaybackEndTime;
+(id)keyPathsForValuesAffectingLoadedTimeRanges;
+(id)keyPathsForValuesAffectingUsesExternalPlaybackWhileExternalScreenIsActive;
+(id)keyPathsForValuesAffectingContentDuration;
+(id)keyPathsForValuesAffectingExternalPlaybackType;
+(id)keyPathsForValuesAffectingHasVideo;
+(id)keyPathsForValuesAffectingCanSeekFrameBackward;
+(id)keyPathsForValuesAffectingAllowsExternalPlayback;
+(id)keyPathsForValuesAffectingCanTogglePlayback;
+(id)keyPathsForValuesAffectingHasSeekableLiveStreamingContent;
+(id)keyPathsForValuesAffectingCanPlay;
+(id)keyPathsForValuesAffectingHasLiveStreamingContent;
+(id)keyPathsForValuesAffectingError;
+(id)keyPathsForValuesAffectingCanScanForward;
+(id)keyPathsForValuesAffectingPlayingOnExternalScreen;
+(id)keyPathsForValuesAffectingHasEnabledVideo;
+(id)keyPathsForValuesAffectingCanSeekChapterBackward;
+(void)setCachedIsPictureInPictureSupported:(BOOL)arg1 ;
+(id)_sortedAudibleOption:(id)arg1 ;
+(id)keyPathsForValuesAffectingCurrentTime;
+(id)keyPathsForValuesAffectingHasShareableContent;
-(BOOL)canSeekToEnd;
-(long long)frameNumberForCurrentTime;
-(void)seekToTime:(double)arg1 ;
-(void)_playAtRate:(double)arg1 ;
-(AVPlayer *)activePlayer;
-(NSString *)externalPlaybackAirPlayDeviceLocalizedName;
-(BOOL)hasTrimmableContent;
-(void)setCompatibleWithAirPlayVideo:(BOOL)arg1 ;
-(id)_photosensitiveDisplayTimes;
-(id)_outputContext;
-(void)togglePictureInPicture:(id)arg1 ;
-(BOOL)_assetContainsProResRaw:(id)arg1 ;
-(AVAssetTrack *)currentVideoTrack;
-(id)maxTimecode;
-(BOOL)allowsExternalPlayback;
-(BOOL)usesExternalPlaybackWhileExternalScreenIsActive;
-(void)setPresentationSize:(CGSize)arg1 ;
-(void)setHasProtectedContent:(BOOL)arg1 ;
-(BOOL)hasAudioMediaSelectionOptions;
-(void)changeVolumeToMaximum:(id)arg1 ;
-(id)mediaSelectionGroupForMediaCharacteristic:(id)arg1 ;
-(void)setCaptionAppearanceDisplayType:(long long)arg1 ;
-(BOOL)isAtLiveEdge;
-(void)setActiveRate:(double)arg1 ;
-(void)_setRate_AVFoundationStrategy:(double)arg1 ;
-(void)seekToFrame:(long long)arg1 ;
-(BOOL)isDisablingAutomaticTermination;
-(id)seekableTimeRanges;
-(BOOL)hasLiveStreamingContent;
-(id)currentLegibleMediaSelectionOption;
-(void)setPlayingOnSecondScreen:(BOOL)arg1 ;
-(BOOL)isReadyToPlay;
-(BOOL)canScanForward;
-(AVAsset *)currentAssetIfReady;
-(void)setRateWithForce:(double)arg1 ;
-(AVPlayer *)player;
-(BOOL)_assetIsMarkedNotSerializable:(id)arg1 ;
-(void)_setSuspendedRate:(double)arg1 ;
-(void)setTouchBarRequiresLinearPlayback:(BOOL)arg1 ;
-(void)_updateRateForScrubbingAndSeeking;
-(void)_updatePlayerMutedState;
-(void)_setPlaybackSuspended:(BOOL)arg1 ;
-(id)audioWaveform;
-(BOOL)isPlayingOnMatchPointDevice;
-(void)pauseForAllCoordinatedPlaybackParticipants:(BOOL)arg1 ;
-(double)minTime;
-(void)_updateScanningForwardRate;
-(void)seekFrameBackward:(id)arg1 ;
-(void)_setNeedsAtLiveEdgeStateUpdate;
-(void)setRate:(double)arg1 ;
-(BOOL)hasShareableContent;
-(void)_disableLegibleMediaSelectionOptions:(id)arg1 ;
-(void)setAllowsAudioPlayback:(BOOL)arg1 ;
-(void)setAssetBeingPrepared:(AVAsset *)arg1 ;
-(void)setDefaultPlaybackRate:(double)arg1 ;
-(BOOL)volumeControlsCanShowSlider;
-(void)setPlaybackControlsShouldControlSystemVolume:(BOOL)arg1 ;
-(void)pause:(id)arg1 ;
-(BOOL)isPictureInPictureActive;
-(id)legibleOptions;
-(void)setCanTogglePictureInPicture:(BOOL)arg1 ;
-(BOOL)hasLegibleMediaSelectionOptions;
-(void)_updateScanningBackwardRate;
-(void)autoplay:(id)arg1 ;
-(id)_volumeController;
-(NSArray *)photosensitivityRegions;
-(void)setAtLiveEdge:(BOOL)arg1 ;
-(BOOL)isCompletelySeekable;
-(BOOL)_isScanningTV;
-(BOOL)handlesAudioSessionInterruptions;
-(id)visualOptions;
-(void)selectedMediaOptionMayHaveChanged;
-(double)_adjustedSeekTimeFromTime:(double)arg1 toTime:(double)arg2 ;

-(void)setScrubbing:(BOOL)arg1 ;
-(void)setObservationInfo:(void*)arg1 ;
-(void)_updatePhotosensitivityRegions;
-(double)currentTimeWithinEndTimes;
-(void)_updateAtLiveEdgeStateIfNeeded;
-(void)setMaxTime:(double)arg1 ;
-(NSDate *)currentOrEstimatedDate;
-(void)_updateExternalPlaybackAirPlayDeviceLocalizedNameIfNeeded;

-(void)increaseVolume:(id)arg1 ;
-(BOOL)_assetIsRestrictedFromSaving:(id)arg1 ;
-(void)setContentChapters:(NSArray *)arg1 ;
-(void)seekChapterForward:(id)arg1 ;

-(id)audioMediaSelectionOptions;
-(NSArray *)availableMetadataFormats;
-(void)stopGeneratingTimecodes;
-(NSError *)error;
-(void)suspendPlaybackCoordinatorWhileActivelySeekingIfNecessary;
-(id)maxFrameCountString;
-(void)stopUsingNetworkResourcesForLiveStreamingWhilePaused;
-(void)_setMediaOption:(id)arg1 mediaCharacteristic:(id)arg2 ;
-(void)_setMinTiming:(id)arg1 maxTiming:(id)arg2 ;
-(id)_selectedMediaOptionWithMediaCharacteristic:(id)arg1 ;
-(BOOL)avkit_isAVPlayerControllerOrSubclass;
-(void)setCurrentAudioTrack:(AVAssetTrack *)arg1 ;
-(void)setSeekToTime:(double)arg1 ;
-(void)setVolume:(double)arg1 ;
-(BOOL)canSeekFrameForward;
-(float)nominalFrameRate;
-(void)setPlayerLayerForReducingResources:(AVPlayerLayer *)arg1 ;
-(id)_createMetadataDictionaryForCurrentAsset;
-(void)endScanningForward:(id)arg1 ;
-(void)setSeekingInternal:(BOOL)arg1 ;
-(void)setAtMinTime:(BOOL)arg1 ;
-(double)timecodeObservationInterval;
-(BOOL)isAtMinTime;
-(void)scanForward:(id)arg1 ;
-(void)dealloc;
-(void)setPlaybackControlsIncludeVolumeControls:(BOOL)arg1 ;
-(BOOL)isStreaming;
-(BOOL)shouldLoadVisualMediaSelectionOptions;
-(CGSize)presentationSize;
-(BOOL)canSeekToBeginning;
-(void)setInitialScrubbingTime:(double)arg1 ;
-(void)setShouldLoadVisualMediaSelectionOptions:(BOOL)arg1 ;
-(void)_performAutomaticMediaSelectionForUserCaptionDisplayType:(long long)arg1 ;
-(void)toggleMuted:(id)arg1 ;
-(NSDate *)currentDate;
-(BOOL)canSeekFrameBackward;
-(void)setPictureInPictureActive:(BOOL)arg1 ;
-(BOOL)hasVideo;
-(void)setMuted:(BOOL)arg1 ;
-(BOOL)isPictureInPicturePossible;
-(AVMediaSelectionOption *)currentVideoMediaSelectionOption;
-(void)reloadOptionsAndCurrentSelections;
-(CGAffineTransform)preferredTransform;
-(CGSize)maximumVideoResolution;
-(void)setComposable:(BOOL)arg1 ;
-(void)beginScanningBackward:(id)arg1 ;
-(void)togglePlayback:(id)arg1 ;
-(BOOL)isPreventingIdleDisplaySleep;
-(BOOL)isScrubbing;
-(void*)observationInfo;
-(void)skipBackwardThirtySeconds:(id)arg1 ;
-(id)_queuePlayer;
-(id)_optionsForGroup:(id)arg1 ;
-(BOOL)hasEnabledVideo;
-(void)seekFrameForward:(id)arg1 ;
-(double)contentDuration;
-(void)setAllowsPictureInPicturePlayback:(BOOL)arg1 ;
-(id)currentEnabledAssetTrackForMediaType:(id)arg1 ;
-(void)beginScanningForward:(id)arg1 ;
-(double)rateBeforeScrubBegan;
-(void)_ensureUserCaptionDisplayType:(long long)arg1 ;
-(void)setScrubCoordinatorSuspension:(AVCoordinatedPlaybackSuspension *)arg1 ;
-(void)startInspectionIfNeeded;
-(void)reloadAudioOptions;
-(id)init;
-(void)startUsingNetworkResourcesForLiveStreamingWhilePaused;
-(BOOL)isSeekingInternal;
-(void)_cancelOutstandingAtLiveEdgeStateUpdates;
-(BOOL)isPlayableOffline;
-(void)togglePlaybackEvenWhenInBackground:(id)arg1 ;
-(double)seekToTime;
-(void)setAvailableMetadataFormats:(NSArray *)arg1 ;
-(void)_prepareAssetForInspectionIfNeeded;

-(void)_updatePlayingOnMatchPointDeviceIfNeeded;
-(BOOL)canPlay;
-(void)setCurrentAssetIfReady:(AVAsset *)arg1 ;
-(BOOL)startGeneratingTimecodesUsingBlock:(/*^block*/id)arg1 ;
-(void)reloadVisualOptions;
-(void)seekToTimecode:(id)arg1 ;
-(void)_updateCurrentAudioTrackIfNeeded;

-(BOOL)isInspectionSuspended;
-(void)_setupInterstitialController;
-(double)rate;
-(id)loadedTimeRanges;
-(void)beginScrubbing:(id)arg1 ;
-(BOOL)isPlayingOnSecondScreen;
-(void)setHasBegunInspection:(BOOL)arg1 ;
-(BOOL)isReducingResourcesForPictureInPicture;
-(void)_startSuspendingPlayback;
-(BOOL)isComposable;
-(void)setAtMaxTime:(BOOL)arg1 ;
-(void)updateAtMinMaxTime;
-(AVAsset *)assetBeingPrepared;
-(void)_cancelPendingSeeksIfNeeded;
-(void)setCurrentLegibleMediaSelectionOption:(id)arg1 ;
-(void)_updateMinMaxTimingIfNeeded;
-(void)setPlayingOnMatchPointDevice:(BOOL)arg1 ;
-(long long)status;
-(BOOL)hasMediaSelectionOptions;
-(void)scanBackward:(id)arg1 ;
-(double)maxTime;
-(BOOL)isAtMaxTime;
-(long long)timeControlStatus;
-(void)setPictureInPictureSupported:(BOOL)arg1 ;
-(void)setDisablingAutomaticTermination:(BOOL)arg1 ;
-(NSDictionary *)metadata;
-(void)endPlaybackSuspension;
-(void)beginReducingResourcesForPictureInPicturePlayerLayer:(id)arg1 ;
-(void)setCanUseNetworkResourcesForLiveStreamingWhilePaused:(BOOL)arg1 ;
-(BOOL)touchBarRequiresLinearPlayback;
-(double)suspendedRate;
-(BOOL)_mediaSelectionCriteriaCanBeAppliedAutomaticallyToLegibleMediaSelectionGroup;
-(id)currentAudioMediaSelectionOption;
-(void)seekByTimeInterval:(double)arg1 toleranceBefore:(double)arg2 toleranceAfter:(double)arg3 ;
-(id)scanningDelays;
-(void)setPreventingIdleDisplaySleep:(BOOL)arg1 ;
-(BOOL)isPlayingOnExternalScreen;
-(BOOL)hasEnabledAudio;
-(void)setPipActivitySessionIdentifier:(NSString *)arg1 ;
-(void)changeVolumeToMinimum:(id)arg1 ;
-(BOOL)isMuted;
-(void)setExternalPlaybackAirPlayDeviceLocalizedName:(NSString *)arg1 ;
-(void)_updateActivePlayer;
-(void)setCurrentVideoTrack:(AVAssetTrack *)arg1 ;
-(void)endReducingResourcesForPictureInPicturePlayerLayer:(id)arg1 ;

-(void)startKVO;
-(CGSize)contentDimensions;
-(void)setRateBeforeScrubBegan:(double)arg1 ;
-(void)_retryPlayImmediatelyIfNeeded;
-(void)setAudioMediaSelectionOptions:(id)arg1 ;
-(BOOL)isPictureInPictureSupported;
-(BOOL)isCompatibleWithAirPlayVideo;
-(BOOL)isPlaybackSuspended;
-(void)setActivePlayer:(AVPlayer *)arg1 ;
-(void)_commonInit;
-(BOOL)canSeek;
-(id)audioOptions;
-(void)beginScrubbing;
-(void)setCurrentAudioMediaSelectionOption:(id)arg1 ;
-(AVCoordinatedPlaybackSuspension *)scrubCoordinatorSuspension;
-(void)setPictureInPictureInterrupted:(BOOL)arg1 ;
-(void)gotoEndOfSeekableRanges:(id)arg1 ;
-(void)setPlayer:(AVPlayer *)arg1 ;
-(void)selectedMediaOptionMayHaveChanged:(BOOL)arg1 ;
-(void)reloadLegibleOptions;
-(void)updateMinMaxTiming;
-(void)setMinTime:(double)arg1 ;
-(NSArray *)visualMediaSelectionOptions;
-(double)initialScrubbingTime;
-(BOOL)coordinatedPlaybackActive;
-(void)setLegibleMediaSelectionOptions:(id)arg1 audioMediaSelectionOptions:(id)arg2 assumeMediaOptionMayHaveChanged:(BOOL)arg3 ;
-(NSArray *)contentChapters;
-(void)seekOrStepByFrameCount:(long long)arg1 ;
-(BOOL)isPlaying;
-(void)_updateMetadata;
-(id)preferredDisplayCriteria;
-(id)_timecodeTrack;
-(BOOL)hasReadableTimecodes;
-(void)_beginPlaybackSuspension_AVFoundationStrategy;
-(void)resumePlaybackCoordinatorIfSuspended;
-(double)contentDurationWithinEndTimes;

-(BOOL)isPictureInPictureInterrupted;
-(double)volume;
-(void)seekToEnd:(id)arg1 ;
-(void)_stopSuspendingPlayback;
-(void)_updateAtLiveEdgeStateAndScheduleTimerIfNeeded;
-(BOOL)isSeeking;
-(double)activeRate;
-(void)decreaseVolume:(id)arg1 ;
-(void)endScanningBackward:(id)arg1 ;
-(NSString *)pipActivitySessionIdentifier;
-(void)setPhotosensitivityRegions:(NSArray *)arg1 ;
-(void)reloadOptions;
-(void)updateTiming;
-(void)setCoordinatedPlaybackActive:(BOOL)arg1 ;
-(BOOL)canTogglePictureInPicture;
-(void)_endPlaybackSuspension_AVFoundationStrategy;
-(BOOL)hasProtectedContent;
-(AVAssetTrack *)currentAudioTrack;
-(void)setMetadata:(NSDictionary *)arg1 ;
-(BOOL)allowsPictureInPicturePlayback;
-(BOOL)canScanBackward;
-(void)seekChapterBackward:(id)arg1 ;
-(BOOL)isPreventingIdleSystemSleep;
-(void)_updateCurrentVideoTrackIfNeeded;
-(void)play:(id)arg1 ;
-(void)endScrubbing;
-(void)_throttledUpdatePlayingOnMatchPointDeviceIfNeededWithContext:(id)arg1 ;
-(void)_updateCoordinatedPlaybackActive;
-(void)_observeValueForKeyPath:(id)arg1 oldValue:(id)arg2 newValue:(id)arg3 ;
-(void)setHandlesAudioSessionInterruptions:(BOOL)arg1 ;
-(void)seekToBeginning:(id)arg1 ;
-(void)setVisualMediaSelectionOptions:(NSArray *)arg1 ;
-(void)_scheduleAtLiveEdgeStateUpdateIfNeeded;
-(BOOL)isExternalPlaybackActive;
-(void)setLooping:(BOOL)arg1 ;
-(void)reloadOptionsAssumingMediaOptionsMayHaveChanged:(BOOL)arg1 ;
-(BOOL)hasContent;
-(double)currentTime;
-(void)beginPlaybackSuspension;
-(void)setSeeking:(BOOL)arg1 ;
-(void)seekToChapter:(id)arg1 ;
-(id)initWithPlayer:(id)arg1 ;
-(BOOL)hasContentChapters;
-(id)timecodeForCurrentTime;
-(AVPlayerLayer *)playerLayerForReducingResources;
-(void)endScrubbing:(id)arg1 ;
-(double)defaultPlaybackRate;
-(void)seekToTime:(double)arg1 toleranceBefore:(double)arg2 toleranceAfter:(double)arg3 ;
-(void)setPlaying:(BOOL)arg1 ;
-(void)setInspectionSuspended:(BOOL)arg1 ;
-(BOOL)canTogglePlayback;
-(BOOL)canSeekChapterForward;
-(void)setAllowsExternalPlayback:(BOOL)arg1 ;
-(BOOL)hasSeekableLiveStreamingContent;
-(void)setScanningTV:(BOOL)arg1 ;
-(long long)captionAppearanceDisplayType;
-(void)setPreventingIdleSystemSleep:(BOOL)arg1 ;
-(BOOL)canUseNetworkResourcesForLiveStreamingWhilePaused;
-(BOOL)hasTimecodes;
-(BOOL)hasBegunInspection;
-(BOOL)canPause;
-(id)loadTimecodeControllerIfNeeded;
-(BOOL)canPlayImmediately;
-(void)_enableAutoMediaSelection:(id)arg1 ;
-(long long)externalPlaybackType;
-(void)_scheduleAtLiveEdgeStateUpdateWithTimeInterval:(double)arg1 ;
-(BOOL)isLooping;
-(id)legibleMediaSelectionOptions;
-(void)seekByTimeInterval:(double)arg1 ;
-(BOOL)allowsAudioPlayback;
-(void)actuallySeekToTime;
-(BOOL)canSeekChapterBackward;
-(void)acquireResourceReductionAssertion;
-(void)setLegibleMediaSelectionOptions:(id)arg1 ;
@end

#endif /* AVPlayerViewController_Swizzling_h */
