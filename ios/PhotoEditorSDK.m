//
//  PhotoEditorSDK.m
//  FantasticPost
//
//  Created by Michel Albers on 16.08.17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "PhotoEditorSDK.h"
#import "React/RCTUtils.h"
#import "AVHexColor.h"

// Config options
NSString* const kBackgroundColorEditorKey = @"backgroundColorEditor";
NSString* const kBackgroundColorMenuEditorKey = @"backgroundColorMenuEditor";
NSString* const kBackgroundColorCameraKey = @"backgroundColorCamera";
NSString* const kIconColor = @"iconColor";
NSString* const kTextColor = @"textColor";
NSString* const kAccentColor = @"accentColor";
NSString* const kCameraRollAllowedKey = @"cameraRowAllowed";
NSString* const kShowFiltersInCameraKey = @"showFiltersInCamera";
NSString* const kSaveIcon = @"saveIcon";
NSString* const kApplyIcon = @"applyIcon";
NSString* const kDiscardIcon = @"discardIcon";

BOOL *processedCustomItems = NO;

// Menu items
typedef enum {
    transformTool,
    filterTool,
    focusTool,
    adjustTool,
    textTool,
    stickerTool,
    overlayTool,
    brushTool,
    magic,
} FeatureType;

@interface PhotoEditorSDK ()

@property (strong, nonatomic) RCTPromiseResolveBlock resolver;
@property (strong, nonatomic) RCTPromiseRejectBlock rejecter;
@property (strong, nonatomic) PESDKPhotoEditViewController* editController;
@property (strong, nonatomic) PESDKCameraViewController* cameraController;


@end

@implementation PhotoEditorSDK
RCT_EXPORT_MODULE(PESDK);

- (NSArray<NSString *> *)supportedEvents
{
	return @[@"LogScreenView"];
}


static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+(NSString *) randomStringWithLength: (int) len {

    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];

    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }

    return randomString;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSDictionary *)constantsToExport
{
    return @{
             @"backgroundColorCameraKey":       kBackgroundColorCameraKey,
             @"backgroundColorEditorKey":       kBackgroundColorEditorKey,
             @"backgroundColorMenuEditorKey":   kBackgroundColorMenuEditorKey,
             @"iconColor":   					kIconColor,
             @"textColor":  					kTextColor,
             @"accentColor":  					kAccentColor,
             @"cameraRollAllowedKey":           kCameraRollAllowedKey,
             @"showFiltersInCameraKey":         kShowFiltersInCameraKey,
             @"saveIcon":      					kSaveIcon,
             @"applyIcon":      				kApplyIcon,
             @"discardIcon":      				kDiscardIcon,
             @"transformTool":                  [NSNumber numberWithInt: transformTool],
             @"filterTool":                     [NSNumber numberWithInt: filterTool],
             @"focusTool":                      [NSNumber numberWithInt: focusTool],
             @"adjustTool":                     [NSNumber numberWithInt: adjustTool],
             @"textTool":                       [NSNumber numberWithInt: textTool],
             @"stickerTool":                    [NSNumber numberWithInt: stickerTool],
             @"overlayTool":                    [NSNumber numberWithInt: overlayTool],
             @"brushTool":                      [NSNumber numberWithInt: brushTool],
             @"magic":                          [NSNumber numberWithInt: magic]
    };
}

-(void)_openEditor: (UIImage *)image config: (PESDKConfiguration *)config features: (NSArray*)features options:(NSDictionary *) options custom:(NSDictionary*) custom resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject {
    self.resolver = resolve;
    self.rejecter = reject;

    // Just an empty model
    PESDKPhotoEditModel* photoEditModel = [[PESDKPhotoEditModel alloc] init];

    // Build the menu items from the features array if present
    NSMutableArray<PESDKPhotoEditMenuItem *>* menuItems = [[NSMutableArray alloc] init];

    // Default features
    if (features == nil || [features count] == 0) {
        features = @[
          [NSNumber numberWithInt: transformTool],
          [NSNumber numberWithInt: filterTool],
          [NSNumber numberWithInt: focusTool],
          [NSNumber numberWithInt: adjustTool],
          [NSNumber numberWithInt: textTool],
          [NSNumber numberWithInt: stickerTool],
          [NSNumber numberWithInt: overlayTool],
          [NSNumber numberWithInt: brushTool],
          [NSNumber numberWithInt: magic]
        ];
    }

    [features enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int feature = [obj intValue];
        switch (feature) {
            case transformTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createTransformToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case filterTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createFilterToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case focusTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createFocusToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case adjustTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createAdjustToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case textTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createTextToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case stickerTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createStickerToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case overlayTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createOverlayToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case brushTool: {
                PESDKToolMenuItem* menuItem = [PESDKToolMenuItem createBrushToolItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithToolMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            case magic: {
                PESDKActionMenuItem* menuItem = [PESDKActionMenuItem createMagicItem];
                PESDKPhotoEditMenuItem* editMenuItem = [[PESDKPhotoEditMenuItem alloc] initWithActionMenuItem:menuItem];
                [menuItems addObject: editMenuItem];
                break;
            }
            default:
                break;
        }
    }];

	/* Check for custom items */
	if ( custom != nil  && processedCustomItems != YES )
	{
		NSNumber *includeDefaultFilters = [NSNumber numberWithBool:YES];
		if ([custom valueForKey:@"includeDefaultFilters"]) {
			includeDefaultFilters = [custom valueForKey:@"includeDefaultFilters"];
		}
		NSNumber *includeDefaultOverlays = [NSNumber numberWithBool:YES];
		if ([custom valueForKey:@"includeDefaultOverlays"]) {
			includeDefaultOverlays = [custom valueForKey:@"includeDefaultOverlays"];
		}
		NSNumber *includeDefaultStickerCategories = [NSNumber numberWithBool:YES];
		if ([custom valueForKey:@"includeDefaultStickerCategories"]) {
			includeDefaultStickerCategories = [custom valueForKey:@"includeDefaultStickerCategories"];
		}

		/* Set custom Filters */
		if ([custom valueForKey:@"filters"] || [includeDefaultFilters boolValue] == NO)
		{
			/* Set Default Filter Array */
			NSMutableArray<PESDKPhotoEffect *> *filters = [[NSMutableArray alloc] init];

			if( [includeDefaultFilters boolValue] == YES ) {
				filters = [[PESDKPhotoEffect allEffects] mutableCopy];
			}else{
				[filters addObject:[[PESDKPhotoEffect alloc] initWithIdentifier:@"None" lutURL:nil displayName: @"None"]];
			}

			/* Set Fitlers */
			if ([custom valueForKey:@"filters"] )
			{
				NSArray<NSDictionary *> *filtersConfig = [custom valueForKey:@"filters"];
				NSEnumerator *enumerator = [filtersConfig objectEnumerator];
				id filter;
				while (filter = [enumerator nextObject]) {
					NSString *filter_id = [filter valueForKey:@"id"];
					NSString *filter_label = [filter valueForKey:@"label"];

					NSString *baseRes = [@"res/" stringByAppendingString:filter_id];

					[filters addObject:[[PESDKPhotoEffect alloc] initWithIdentifier:filter_id lutURL:[[NSBundle mainBundle] URLForResource:baseRes withExtension:@"png"] displayName:filter_label]];
				}

				PESDKPhotoEffect.allEffects = [filters copy];
			}
		}

		/* Set custom Overlays */
		if ([custom valueForKey:@"overlays"] || [includeDefaultOverlays boolValue] == NO)
		{
			/* Set Default Overlay Array */
			NSMutableArray<PESDKOverlay *> *overlays = [[NSMutableArray alloc] init];

			if( [includeDefaultOverlays boolValue] == YES ) {
				overlays = [[PESDKOverlay all] mutableCopy];
			}else{
				[overlays addObject:[PESDKOverlay none]];
			}

			/* Set Overlays */
			if ([custom valueForKey:@"overlays"] )
			{
				NSArray<NSDictionary *> *overlaysConfig = [custom valueForKey:@"overlays"];
				NSEnumerator *enumerator = [overlaysConfig objectEnumerator];
				id overlay;
				while (overlay = [enumerator nextObject]) {
					NSString *overlay_id = [overlay valueForKey:@"id"];
					NSString *overlay_label = [overlay valueForKey:@"label"];
					NSString *overlay_blendmode = [[overlay valueForKey:@"blendMode"] lowercaseString];

					int defaultBlendMode = PESDKBlendModeNormal;
					if([overlay_blendmode isEqualToString:@"color_burn"]){
                    	defaultBlendMode = PESDKBlendModeColorBurn;
                    }else if([overlay_blendmode isEqualToString:@"darken"]){
                        defaultBlendMode = PESDKBlendModeDarken;
                    }else if([overlay_blendmode isEqualToString:@"lighten"]){
                        defaultBlendMode = PESDKBlendModeLighten;
                    }else if([overlay_blendmode isEqualToString:@"hard_light"]){
                        defaultBlendMode = PESDKBlendModeHardLight;
                    }else if([overlay_blendmode isEqualToString:@"soft_light"]){
                        defaultBlendMode = PESDKBlendModeSoftLight;
                    }else if([overlay_blendmode isEqualToString:@"multiply"]){
                        defaultBlendMode = PESDKBlendModeMultiply;
                    }else if([overlay_blendmode isEqualToString:@"overlay"]){
                        defaultBlendMode = PESDKBlendModeOverlay;
                    }else if([overlay_blendmode isEqualToString:@"screen"]){
                        defaultBlendMode = PESDKBlendModeScreen;
                    }else if([overlay_blendmode isEqualToString:@"normal"]){
                        defaultBlendMode = PESDKBlendModeNormal;
                    }

					NSString *baseRes = [@"res/" stringByAppendingString:overlay_id];

					[overlays addObject:[[PESDKOverlay alloc] initWithIdentifier:overlay_id displayName:overlay_label url:[[NSBundle mainBundle] URLForResource:baseRes withExtension:@"png"] thumbnailURL:[[NSBundle mainBundle] URLForResource:[baseRes stringByAppendingString:@"_thumb"] withExtension:@"png"] initialBlendMode:defaultBlendMode]];
				}

				PESDKOverlay.all = [overlays copy];
			}
		}


		/* Set custom Stickers */
		if ([custom valueForKey:@"stickerCategories"] || [includeDefaultStickerCategories boolValue] == NO)
		{
			/* Set Default Sticker Category Array */
			NSMutableArray<PESDKStickerCategory *> *stickerCats = [[NSMutableArray alloc] init];

			if( [includeDefaultStickerCategories boolValue] == YES ) {
				stickerCats = [[PESDKStickerCategory all] mutableCopy];
			}

			/* Set Sticker Categories */
			if ([custom valueForKey:@"stickerCategories"] )
			{
				NSArray<NSDictionary *> *stickerCatsConfig = [custom valueForKey:@"stickerCategories"];
				NSEnumerator *enumerator = [stickerCatsConfig objectEnumerator];
				id stickerCat;
				while (stickerCat = [enumerator nextObject]) {
					NSString *stickerCat_id = [stickerCat valueForKey:@"id"];
					NSString *stickerCat_label = [stickerCat valueForKey:@"label"];

					NSMutableArray<PESDKSticker *> *stickers = [[NSMutableArray alloc] init];

					/* Set Stickers */
					if ([stickerCat valueForKey:@"stickers"] )
					{
						NSArray<NSDictionary *> *stickersArray = [stickerCat valueForKey:@"stickers"];
						NSEnumerator *stickerEnumerator = [stickersArray objectEnumerator];
						id sticker;
						while (sticker = [stickerEnumerator nextObject]) {
							NSString *sticker_id = [sticker valueForKey:@"id"];
							NSString *sticker_label = sticker_id;
							if ([sticker valueForKey:@"label"] )
								sticker_label = [sticker valueForKey:@"label"];

							NSString *sticker_tint = @"none";
								sticker_tint = [[sticker valueForKey:@"tintMode"] lowercaseString];

							int tintMode = PESDKStickerTintModeNone;
							if([sticker_tint isEqualToString:@"colorized"]){
		                    	tintMode = PESDKStickerTintModeColorized;
		                    }else if([sticker_tint isEqualToString:@"none"]){
		                        tintMode = PESDKStickerTintModeNone;
		                    }

							NSString *baseRes = [@"res/" stringByAppendingString:sticker_id];

							[stickers addObject:[[PESDKSticker alloc] initWithImageURL:[[NSBundle mainBundle] URLForResource:baseRes withExtension:@"png"] thumbnailURL:[[NSBundle mainBundle] URLForResource:[baseRes stringByAppendingString:@"_thumb"] withExtension:@"png"] tintMode: tintMode identifier:sticker_id]];
						}
					}

					NSString *catBaseRes = [@"res/" stringByAppendingString:stickerCat_id];

					[stickerCats addObject:[[PESDKStickerCategory alloc] initWithTitle:stickerCat_label imageURL:[[NSBundle mainBundle] URLForResource:catBaseRes withExtension:@"png"] stickers:stickers]];
				}

				PESDKStickerCategory.all = [stickerCats copy];
			}


		}

		processedCustomItems = YES;
	}


    self.editController = [[PESDKPhotoEditViewController alloc] initWithPhoto:image configuration:config menuItems:menuItems photoEditModel:photoEditModel];
    self.editController.delegate = self;
    UIViewController *currentViewController = RCTPresentedViewController();

	if ([options valueForKey:kBackgroundColorEditorKey]) {
		self.editController.toolbar.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorEditorKey]];
	}

    dispatch_async(dispatch_get_main_queue(), ^{
        [currentViewController presentViewController:self.editController animated:YES completion:nil];
    });
}

-(PESDKConfiguration*)_buildConfig: (NSDictionary *)options custom:(NSDictionary*) custom {
    PESDKConfiguration* config = [[PESDKConfiguration alloc] initWithBuilder:^(PESDKConfigurationBuilder * builder) {

		if ([options valueForKey:kBackgroundColorEditorKey]) {
			builder.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorEditorKey]];
		}

		if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
			builder.menuBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
		}

        [builder configurePhotoEditorViewController:^(PESDKPhotoEditViewControllerOptionsBuilder * b) {
            if ([options valueForKey:kBackgroundColorEditorKey]) {
                b.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorEditorKey]];
            }

            if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
                b.menuBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
            }

			b.actionButtonConfigurationBlock = ^(PESDKIconCaptionCollectionViewCell * _Nonnull cell, PESDKPhotoEditMenuItem * _Nonnull menuItem) {

				
				if(custom != nil)
				{
					/* Set custom Menu labels and icons */
					if ([custom valueForKey:@"toolsMenu"])
					{	
						NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];

						for (NSString* key in toolsMenu) {
							id tool = [toolsMenu objectForKey:key];

							if ([menuItem.toolMenuItem.title isEqualToString:key]) {
								
								if([tool valueForKey:@"label"]) {
									cell.captionLabel.text =  [tool valueForKey:@"label"];
								}
								
								if([tool valueForKey:@"icon"]) {
									NSString *baseRes = [@"res/" stringByAppendingString:[tool valueForKey:@"icon"]];
									UIImage *image = [UIImage imageNamed:baseRes];
									cell.imageView.image = image;
								}
							}
						}
					}
				}

			  	if ([options valueForKey:kIconColor]) {
					cell.iconTintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];;
				}
			  	if ([options valueForKey:kTextColor]) {
				    cell.captionTintColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kSaveIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kSaveIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

			b.overlayButtonConfigurationClosure = ^(PESDKOverlayButton * _Nonnull button, enum PhotoEditOverlayAction menuItem) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					button.backgroundColor = [[AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]] colorWithAlphaComponent:0.8];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
        }];

        [builder configureCameraViewController:^(PESDKCameraViewControllerOptionsBuilder * b) {
            if ([options valueForKey:kBackgroundColorCameraKey]) {
                b.backgroundColor = [AVHexColor colorWithHexString: (NSString*)[options valueForKey:kBackgroundColorCameraKey]];
            }

            if ([[options allKeys] containsObject:kCameraRollAllowedKey]) {
                b.showCameraRoll = [[options valueForKey:kCameraRollAllowedKey] boolValue];
            }

            if ([[options allKeys] containsObject: kShowFiltersInCameraKey]) {
                b.showFilters = [[options valueForKey:kShowFiltersInCameraKey] boolValue];
            }

            // TODO: Video recording not supported currently
            b.allowedRecordingModesAsNSNumbers = @[[NSNumber numberWithInteger:RecordingModePhoto]];
        }];


		[builder configureTransformToolController:^(PESDKTransformToolControllerOptionsBuilder * _Nonnull b) {
			if(custom != nil)
			{
				NSNumber *includeDefaultTransforms = [NSNumber numberWithBool:YES];
				if ([custom valueForKey:@"includeDefaultTransforms"]) {
					includeDefaultTransforms = [custom valueForKey:@"includeDefaultTransforms"];
				}

				/* Set custom Transforms */
				if ([custom valueForKey:@"transforms"] || [includeDefaultTransforms boolValue] == NO)
				{
					/* Set Default Transforms Array */
					NSMutableArray<UIColor *> *transforms = [[NSMutableArray alloc] init];

					if( [includeDefaultTransforms boolValue] == YES ) {
						transforms = [[b allowedCropRatios] mutableCopy];
					}

					/* Set Transforms */
					if ([custom valueForKey:@"transforms"] )
					{
						NSArray<NSString *> *transformsConfig = [custom valueForKey:@"transforms"];
						NSEnumerator *enumerator = [transformsConfig objectEnumerator];
						id transform;
						while (transform = [enumerator nextObject]) {
							NSNumber *rotatable = [NSNumber numberWithBool:YES];
							if ([transform valueForKey:@"rotatable"]) {
								rotatable = [transform valueForKey:@"rotatable"];
							}

							NSNumber *width = 0;
							if ([transform valueForKey:@"width"]) {
								width = [transform valueForKey:@"width"];
							}

							NSNumber *height = 0;
							if ([transform valueForKey:@"height"]) {
								height = [transform valueForKey:@"height"];
							}
							
							[transforms addObject:[[PESDKCropAspect alloc] initWithWidth:[width floatValue] height:[height floatValue] localizedName:[transform valueForKey:@"label"] rotatable:[rotatable boolValue]]];
						}

						b.allowedCropRatios = [transforms copy];
					}
				}
			}
			
			/*b.transformButtonConfigurationClosure = ^(PESDKButton * _Nonnull button, enum TransformAction menuItem) {
			  	if ([options valueForKey:kIconColor]) {
				    button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};*/
			b.cropAspectButtonConfigurationClosure = ^(PESDKLabelBorderedCollectionViewCell * _Nonnull cell, PESDKCropAspect * menuItem) {
			  	if ([options valueForKey:kTextColor]) {
				    cell.textLabelTintColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}

				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Transform"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Transform"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureFilterToolController:^(PESDKFilterToolControllerOptionsBuilder * _Nonnull b) {
			b.filterIntensitySliderContainerConfigurationClosure = ^(UIView * _Nonnull view) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					view.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
				}
			};
			b.filterIntensitySliderConfigurationClosure = ^(PESDKSlider * _Nonnull slider) {
				if ([options valueForKey:kAccentColor]) {
					slider.filledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbTintColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
				}
				if ([options valueForKey:kIconColor]) {
					slider.unfilledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			/*
			b.filterCellConfigurationClosure = ^(PESDKFilterCollectionViewCell * _Nonnull cell, PESDKPhotoEffect * menuItem) {
			  	if ([options valueForKey:kAccentColor]) {
				    cell.selectionIndicator.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
				}
			};*/

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Filter"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Filter"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

		}];
		[builder configureFocusToolController:^(PESDKFocusToolControllerOptionsBuilder * _Nonnull b) {

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Focus"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Focus"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureAdjustToolController:^(PESDKAdjustToolControllerOptionsBuilder * _Nonnull b) {

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Adjust"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Adjust"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureTextToolController:^(PESDKTextToolControllerOptionsBuilder * _Nonnull b) {

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Text"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Text"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureStickerOptionsToolController:^(PESDKStickerOptionsToolControllerOptionsBuilder * _Nonnull b) {
			b.actionButtonConfigurationClosure = ^(UICollectionViewCell * _Nonnull view, enum StickerAction menuItem) {
			 	PESDKIconCaptionCollectionViewCell *cell = (PESDKIconCaptionCollectionViewCell *)view;

			  	if ([options valueForKey:kIconColor]) {
					cell.iconTintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];;
				}
			  	if ([options valueForKey:kTextColor]) {
				    cell.captionTintColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};

			b.overlayButtonConfigurationClosure = ^(PESDKOverlayButton * _Nonnull button, enum StickerOverlayAction menuItem) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					button.backgroundColor = [[AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]] colorWithAlphaComponent:0.8];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Sticker"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Sticker"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureStickerToolController:^(PESDKStickerToolControllerOptionsBuilder * _Nonnull b) {

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureOverlayToolController:^(PESDKOverlayToolControllerOptionsBuilder * _Nonnull b) {
			b.overlayIntensitySliderContainerConfigurationClosure = ^(UIView * _Nonnull view) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					view.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
				}
			};
			b.overlayIntensitySliderConfigurationClosure = ^(PESDKSlider * _Nonnull slider) {
				if ([options valueForKey:kAccentColor]) {
					slider.filledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbTintColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
				}
				if ([options valueForKey:kIconColor]) {
					slider.unfilledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

			b.overlayModeSelectionViewConfigurationClosure = ^(UICollectionView * _Nonnull view) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					view.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
				}
			};
			b.overlayModeSelectionCellConfigurationClosure = ^(PESDKLabelBorderedCollectionViewCell * _Nonnull cell, enum PESDKBlendMode menuItem) {
				if ([options valueForKey:kTextColor]) {
					cell.textLabelTintColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Overlay"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Overlay"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
		[builder configureBrushToolController:^(PESDKBrushToolControllerOptionsBuilder * _Nonnull b) {
		
			b.defaultBrushColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
			
			b.sliderContainerConfigurationClosure = ^(UIView * _Nonnull view) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					view.backgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]];
				}
			};
			b.sliderConfigurationClosure = ^(PESDKSlider * _Nonnull slider) {
				if ([options valueForKey:kAccentColor]) {
					slider.filledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbTintColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
					slider.thumbBackgroundColor = [AVHexColor colorWithHexString: [options valueForKey:kAccentColor]];
				}
				if ([options valueForKey:kIconColor]) {
					slider.unfilledTrackColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

			b.brushToolButtonConfigurationClosure = ^(UICollectionViewCell * _Nonnull view, enum BrushTool menuItem) {
			 	PESDKIconCaptionCollectionViewCell *cell = (PESDKIconCaptionCollectionViewCell *)view;

			  	if ([options valueForKey:kIconColor]) {
					cell.iconTintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];;
				}
			  	if ([options valueForKey:kTextColor]) {
				    cell.captionTintColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};

			b.overlayButtonConfigurationClosure = ^(PESDKOverlayButton * _Nonnull button, enum BrushOverlayAction menuItem) {
				if ([options valueForKey:kBackgroundColorMenuEditorKey]) {
					button.backgroundColor = [[AVHexColor colorWithHexString: [options valueForKey:kBackgroundColorMenuEditorKey]] colorWithAlphaComponent:0.8];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
				
				/* Set custom Menu label */
				if (custom != nil && [custom valueForKey:@"toolsMenu"])
				{	
					NSDictionary *toolsMenu = [custom valueForKey:@"toolsMenu"];
					if([toolsMenu valueForKey:@"Brush"]) {
						NSDictionary *tool = [toolsMenu objectForKey:@"Brush"];
						if([tool valueForKey:@"label"]) {
							label.text =  [tool valueForKey:@"label"];
						}
					}
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];

		// Configure default color selections
		[builder configureBrushColorToolController:^(PESDKBrushColorToolControllerOptionsBuilder * b) {
			if(custom != nil)
			{
				NSNumber *includeDefaultBrushColors = [NSNumber numberWithBool:YES];
				if ([custom valueForKey:@"includeDefaultBrushColors"]) {
					includeDefaultBrushColors = [custom valueForKey:@"includeDefaultBrushColors"];
				}

				/* Set custom Brush Colors */
				if ([custom valueForKey:@"brushColors"] || [includeDefaultBrushColors boolValue] == NO)
				{
					/* Set Default Brush Colors Array */
					NSMutableArray<UIColor *> *brushColors = [[NSMutableArray alloc] init];

					if( [includeDefaultBrushColors boolValue] == YES ) {
						brushColors = [[b availableColors] mutableCopy];
					}

					/* Set Brush Colors */
					if ([custom valueForKey:@"brushColors"] )
					{
						NSArray<NSString *> *brushConfig = [custom valueForKey:@"brushColors"];
						NSEnumerator *enumerator = [brushConfig objectEnumerator];
						id brushColor;
						while (brushColor = [enumerator nextObject]) {
							[brushColors addObject:[AVHexColor colorWithHexString: brushColor]];
						}

						b.availableColors = [brushColors copy];
					}
				}
			}


			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];

		[builder configureStickerColorToolController:^(PESDKColorToolControllerOptionsBuilder * b) {
			if(custom != nil)
			{
				NSNumber *includeDefaultStickerColors = [NSNumber numberWithBool:YES];
				if ([custom valueForKey:@"includeDefaultStickerColors"]) {
					includeDefaultStickerColors = [custom valueForKey:@"includeDefaultStickerColors"];
				}

				/* Set custom Sticker Colors */
				if ([custom valueForKey:@"stickerColors"] || [includeDefaultStickerColors boolValue] == NO)
				{
					/* Set Default Sticker Colors Array */
					NSMutableArray<UIColor *> *stickerColors = [[NSMutableArray alloc] init];

					if( [includeDefaultStickerColors boolValue] == YES ) {
						stickerColors = [[b availableColors] mutableCopy];
					}

					/* Set Sticker Colors */
					if ([custom valueForKey:@"stickerColors"] )
					{
						NSArray<NSString *> *stickerConfig = [custom valueForKey:@"stickerColors"];
						NSEnumerator *enumerator = [stickerConfig objectEnumerator];
						id stickerColor;
						while (stickerColor = [enumerator nextObject]) {
							[stickerColors addObject:[AVHexColor colorWithHexString: stickerColor]];
						}

						b.availableColors = [stickerColors copy];
					}
				}
			}

			b.titleViewConfigurationClosure = ^(UIView * _Nonnull view) {
				UILabel *label = (UILabel *)view;
				if ([options valueForKey:kTextColor]) {
					label.textColor = [AVHexColor colorWithHexString: [options valueForKey:kTextColor]];
				}
			};
			b.discardButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kDiscardIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kDiscardIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
			b.applyButtonConfigurationClosure = ^(PESDKButton * _Nonnull button) {
				if ([options valueForKey:kApplyIcon]) {
					NSString *baseRes = [@"res/" stringByAppendingString:[options valueForKey:kApplyIcon]];
					UIImage *image = [UIImage imageNamed:baseRes];
					[button setImage:image forState:UIControlStateNormal];
				}

				if ([options valueForKey:kIconColor]) {
					UIImage *image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					[button setImage:image forState:UIControlStateNormal];
					button.tintColor = [AVHexColor colorWithHexString: [options valueForKey:kIconColor]];
				}
			};
		}];
    }];

    return config;
}

RCT_EXPORT_METHOD(openEditor: (NSString*)path options: (NSArray *)features options: (NSDictionary*) options custom:(NSDictionary*) custom resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject) {
    UIImage* image = [UIImage imageWithContentsOfFile: path];
    PESDKConfiguration* config = [self _buildConfig:options custom:custom];

	PESDK.analytics.isEnabled = YES;
	[PESDK.analytics addAnalyticsClient:[[AnalyticsClient alloc] initWithMain:self]];

	dispatch_sync(dispatch_get_main_queue(), ^{  
    	[self _openEditor:image config:config features:features options:options custom:custom resolve:resolve reject:reject];
	});
}

- (void)close {
    UIViewController *currentViewController = RCTPresentedViewController();
    [currentViewController dismissViewControllerAnimated:YES completion:nil];
}

RCT_EXPORT_METHOD(openCamera: (NSArray*) features options:(NSDictionary*) options custom:(NSDictionary*) custom resolve: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject) {
    __weak typeof(self) weakSelf = self;
    UIViewController *currentViewController = RCTPresentedViewController();
    PESDKConfiguration* config = [self _buildConfig:options custom:custom];
	
    self.cameraController = [[PESDKCameraViewController alloc] initWithConfiguration:config];

	PESDK.analytics.isEnabled = YES;
	[PESDK.analytics addAnalyticsClient:[[AnalyticsClient alloc] initWithMain:self]];

	dispatch_sync(dispatch_get_main_queue(), ^{ 
		[self.cameraController.cameraController setupWithInitialRecordingMode:RecordingModePhoto error:nil];

		UISwipeGestureRecognizer* swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
		swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

		[self.cameraController.view addGestureRecognizer:swipeDownRecognizer];
		[self.cameraController setCompletionBlock:^(UIImage * image, NSURL * _) {
			[currentViewController dismissViewControllerAnimated:YES completion:^{
				[weakSelf _openEditor:image config:config features:features options:options custom:custom resolve:resolve reject:reject];
			}];
		}];

		[currentViewController presentViewController:self.cameraController animated:YES completion:nil];
	});
}

-(void)photoEditViewControllerDidCancel:(PESDKPhotoEditViewController *)photoEditViewController {
    if (self.rejecter != nil) {
        self.rejecter(@"DID_CANCEL", @"User did cancel the editor", nil);
        self.rejecter = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });
    }
}

-(void)photoEditViewControllerDidFailToGeneratePhoto:(PESDKPhotoEditViewController *)photoEditViewController {
    if (self.rejecter != nil) {
        self.rejecter(@"DID_FAIL_TO_GENERATE_PHOTO", @"Photo generation failed", nil);
        self.rejecter = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
        });

    }
}

-(void)photoEditViewController:(PESDKPhotoEditViewController *)photoEditViewController didSaveImage:(UIImage *)image imageAsData:(NSData *)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
	if([data length] == 0)
		data = UIImageJPEGRepresentation(image, 0.85);

    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *randomPath = [PhotoEditorSDK randomStringWithLength:10];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:
                      [randomPath stringByAppendingString:@".jpg"] ];

    [data writeToFile:path atomically:YES];

	UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	
    self.resolver(path);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.editController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    });

}

@end


@interface AnalyticsClient ()

@property (strong, nonatomic) PhotoEditorSDK* main;

@end

@implementation AnalyticsClient

-(id)initWithMain:(PhotoEditorSDK *)mainClass {
	if( self = [super init] ) {
		self.main = mainClass;
	}

	return self;
}

-(void)logScreenView:(PESDKAnalyticsScreenViewName _Nonnull)screenView {

	if(screenView != @""){
		[self.main sendEventWithName:@"LogScreenView" body:screenView];
	}
}

-(void)logEvent:(PESDKAnalyticsEventName _Nonnull)event attributes:(NSDictionary<PESDKAnalyticsEventAttributeName, id> * _Nullable)attributes {
}


@end