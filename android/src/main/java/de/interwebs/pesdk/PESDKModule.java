/**
 * PhotoEditorSDK ReactNative Module
 *
 * Created 08/2017 by Interwebs UG (haftungsbeschränkt)
 * @author Michel Albers <m.albers@interwebs-ug.de>
 * @license The Unlincese (unlincese.org)
 *
 */

package de.interwebs.pesdk;

import nl.onstuimig.perfectphoto.CustomEventTracker;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Dynamic;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import ly.img.android.sdk.decoder.ImageSource;
import ly.img.android.sdk.filter.LutColorFilter;
import ly.img.android.sdk.filter.NoneImageFilter;
import ly.img.android.sdk.models.config.ColorConfig;
import ly.img.android.sdk.models.config.CropAspectConfig;
import ly.img.android.sdk.models.config.Divider;
import ly.img.android.sdk.models.config.StickerCategoryConfig;
import ly.img.android.sdk.models.config.ImageStickerConfig;
import ly.img.android.sdk.models.config.interfaces.AspectConfigInterface;
import ly.img.android.sdk.models.config.interfaces.ColorConfigInterface;
import ly.img.android.sdk.models.config.interfaces.ImageFilterInterface;
import ly.img.android.sdk.models.config.interfaces.ToolConfigInterface;
import ly.img.android.sdk.models.config.interfaces.StickerListConfigInterface;
import ly.img.android.sdk.models.config.interfaces.StickerConfigInterface;
import ly.img.android.sdk.models.config.OverlayConfig;
import ly.img.android.sdk.models.constant.BlendMode;
import ly.img.android.sdk.models.constant.Directory;
import ly.img.android.sdk.models.state.CameraSettings;
import ly.img.android.sdk.models.state.EditorLoadSettings;
import ly.img.android.sdk.models.state.EditorMenuState;
import ly.img.android.sdk.models.state.EditorSaveSettings;
import ly.img.android.sdk.models.state.PESDKConfig;
import ly.img.android.sdk.models.state.manager.SettingsList;
import ly.img.android.sdk.tools.BrushEditorTool;
import ly.img.android.sdk.tools.ColorAdjustmentTool;
import ly.img.android.sdk.tools.FilterEditorTool;
import ly.img.android.sdk.tools.FocusEditorTool;
import ly.img.android.sdk.tools.OverlayEditorTool;
import ly.img.android.sdk.tools.StickerEditorTool;
import ly.img.android.sdk.tools.TextEditorTool;
import ly.img.android.sdk.tools.TransformEditorTool;
import ly.img.android.ui.activities.CameraPreviewBuilder;
import ly.img.android.ui.activities.ImgLyIntent;
import ly.img.android.ui.activities.PhotoEditorBuilder;


public class PESDKModule extends ReactContextBaseJavaModule {

    // the answer to life the universe and everything
    static final int RESULT_CODE_PESDK = 42;

    // Promise for later use
    private Promise mPESDKPromise;

    // Error constants
    private static final String E_ACTIVITY_DOES_NOT_EXIST = "ACTIVITY_DOES_NOT_EXIST";
    private static final String E_PESDK_CANCELED = "USER_CANCELED_EDITING";

    // Features
    public static final String transformTool = "transformTool";
    public static final String filterTool = "filterTool";
    public static final String focusTool = "focusTool";
    public static final String adjustTool = "adjustTool";
    public static final String textTool = "textTool";
    public static final String stickerTool = "stickerTool";
    public static final String overlayTool = "overlayTool";
    public static final String brushTool = "brushTool";
    public static final String magic = "magic";

    // Config options
    public static final String backgroundColorCameraKey = "backgroundColor";
    public static final String backgroundColorEditorKey = "backgroundColorEditor";
    public static final String backgroundColorMenuEditorKey = "backgroundColorMenuEditor";
    public static final String cameraRollAllowedKey = "cameraRollAllowed";
    public static final String showFiltersInCameraKey = "showFiltersInCamera";

    private ReactApplicationContext ctx;

    // Listen for onActivityResult
    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            switch (requestCode) {
                case RESULT_CODE_PESDK: {
                    switch (resultCode) {
                        case Activity.RESULT_CANCELED:
                            mPESDKPromise.reject(E_PESDK_CANCELED, "Editor was cancelled");
                            break;
                        case Activity.RESULT_OK:
                            String resultPath = data.getStringExtra(ImgLyIntent.RESULT_IMAGE_PATH);
                            mPESDKPromise.resolve(resultPath);
                            break;
                    }
                    mPESDKPromise = null;
                    break;
                }
            }
        }
    };


    public PESDKModule(ReactApplicationContext context) {
        super(context);
        context.addActivityEventListener(mActivityEventListener);

        ctx = context;
    }

    // Config builder
    private SettingsList buildConfig(ReadableMap options, @Nullable ReadableArray features, @Nullable ReadableMap custom, @Nullable String imagePath) {
        SettingsList settingsList = new SettingsList();
        settingsList
                .getSettingsModel(EditorLoadSettings.class)
                .setImageSourcePath(imagePath)
                .getSettingsModel(EditorSaveSettings.class)
                // TODO: Make export directory configurable
                .setExportDir(Directory.DCIM, "PESDK")
                .setExportPrefix("PESDK_")
                .setSavePolicy(
                        EditorSaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT
                );


        settingsList.setEventProcessor(de.interwebs.pesdk.PESDKEvents.class);
        settingsList.setEventTracker(new CustomEventTracker("UA-35482641-44"));

                // TODO: Config options in PESDK v5 are limited compared to iOS (or I didn't find them)

        PESDKConfig config = settingsList.getConfig();



        ArrayList<ToolConfigInterface> tools = new ArrayList<>();
        ArrayList featureList;

        if (features == null || features.size() == 0) {
            featureList = new ArrayList();
            featureList.add(transformTool);
            featureList.add(filterTool);
            featureList.add(focusTool);
            featureList.add(adjustTool);
            featureList.add(textTool);
            featureList.add(stickerTool);
            featureList.add(overlayTool);
            featureList.add(brushTool);
            featureList.add(magic);
        } else {
            featureList = features.toArrayList();
        }


        for (Object f: featureList) {
            String feature = f.toString();
            switch (feature) {
                case transformTool:
                    tools.add(new TransformEditorTool(R.string.imgly_tool_name_crop, R.drawable.imgly_icon_tool_transform));
                    break;
                case filterTool:
                    tools.add(new FilterEditorTool(R.string.imgly_tool_name_filter, R.drawable.imgly_icon_tool_filters));
                    break;
                case focusTool:
                    tools.add(new FocusEditorTool(R.string.imgly_tool_name_focus, R.drawable.imgly_icon_tool_focus));
                    break;
                case adjustTool:
                    tools.add(new ColorAdjustmentTool(R.string.imgly_tool_name_adjust, R.drawable.imgly_icon_tool_adjust));
                    break;
                case textTool:
                    tools.add(new TextEditorTool(R.string.imgly_tool_name_text, R.drawable.imgly_icon_tool_text));
                    break;
                case stickerTool:
                    tools.add(new StickerEditorTool(R.string.imgly_tool_name_sticker, R.drawable.imgly_icon_tool_sticker));
                    break;
                case overlayTool:
                    tools.add(new OverlayEditorTool(R.string.imgly_tool_name_overlay, R.drawable.imgly_icon_tool_overlay));
                    break;
                case brushTool:
                    tools.add(new BrushEditorTool(R.string.imgly_tool_name_brush, R.drawable.imgly_icon_tool_brush));
                    break;
                case magic:
                    // No magic tool on android
                    break;
            }
        }

        config.setTools(tools);

        if ( custom != null )
        {
            Boolean includeDefaultFilters = custom.hasKey("includeDefaultFilters") ? custom.getBoolean("includeDefaultFilters") : true;
            Boolean includeDefaultOverlays = custom.hasKey("includeDefaultOverlays") ? custom.getBoolean("includeDefaultOverlays") : true;
            Boolean includeDefaultStickerCategories = custom.hasKey("includeDefaultStickerCategories") ? custom.getBoolean("includeDefaultStickerCategories") : true;
            Boolean includeDefaultBrushColors = custom.hasKey("includeDefaultBrushColors") ? custom.getBoolean("includeDefaultBrushColors") : true;
            Boolean includeDefaultStickerColors = custom.hasKey("includeDefaultStickerColors") ? custom.getBoolean("includeDefaultStickerColors") : true;
            Boolean includeDefaultTransforms = custom.hasKey("includeDefaultTransforms") ? custom.getBoolean("includeDefaultTransforms") : true;

            /* Set custom Filters */
            if( custom.hasKey("filters") || includeDefaultFilters == false )
            {
                /* Set Default Filter Array */
                ArrayList<ImageFilterInterface> filters = new ArrayList<ImageFilterInterface>();

                if(includeDefaultFilters){
                    filters = config.getFilterConfig();
                }else{
                    filters.add(new NoneImageFilter());
                }


                /* Set Filters */
                if( custom.hasKey("filters") ) {
                    ReadableArray filtersConfig = custom.getArray("filters");
                    for (int i = 0; i < filtersConfig.size(); i++) {
                        ReadableMap filter = filtersConfig.getMap(i);
                        String filter_id = filter.getString("id");
                        String filter_label = filter.getString("label");

                        int vTiles = 5;
                        int hTiles = 5;
                        int textureSize = 128;

                        String[] filter_segments = filter_id.split("_");
                        if(filter_segments.length >= 4){
                            textureSize = Integer.parseInt(filter_segments[filter_segments.length-1]);
                            hTiles = Integer.parseInt(filter_segments[filter_segments.length-2]);
                            vTiles = Integer.parseInt(filter_segments[filter_segments.length-3]);
                        }

                        filters.add(new LutColorFilter(filter_id, ctx.getResources().getIdentifier(filter_id, "string", ctx.getPackageName()), R.drawable.imgly_filter_preview_photo, ImageSource.create(ctx.getResources().getIdentifier(filter_id, "drawable", ctx.getPackageName())), vTiles, hTiles, textureSize));
                    }
                }

                config.setFilters(filters);
            }

            /* Set custom Overlays */
            if( custom.hasKey("overlays") || includeDefaultOverlays == false )
            {
                /* Set Default Overlay Array */
                ArrayList<OverlayConfig> overlays = new ArrayList<OverlayConfig>();

                if(includeDefaultFilters){
                    overlays = config.getOverlays();
                }else{
                    overlays.add(OverlayConfig.NON_BACKDROP);
                }


                /* Set Overlays */
                if( custom.hasKey("overlays") ){
                    ReadableArray overlaysConfig = custom.getArray("overlays");
                    for (int i = 0; i < overlaysConfig.size(); i++) {
                        ReadableMap overlay = overlaysConfig.getMap(i);
                        String overlay_id = overlay.getString("id");
                        String overlay_label = overlay.getString("label");
                        String overlay_blendmode = overlay.getString("blendMode").toLowerCase();

                        BlendMode defaultBlendMode = BlendMode.NORMAL;
                        switch(overlay_blendmode){
                            case "color_burn":
                            defaultBlendMode = BlendMode.COLOR_BURN;
                            break;
                            case "darken":
                                defaultBlendMode = BlendMode.DARKEN;
                                break;
                            case "lighten":
                                defaultBlendMode = BlendMode.LIGHTEN;
                                break;
                            case "hard_light":
                                defaultBlendMode = BlendMode.HARD_LIGHT;
                                break;
                            case "soft_light":
                                defaultBlendMode = BlendMode.SOFT_LIGHT;
                                break;
                            case "multiply":
                                defaultBlendMode = BlendMode.MULTIPLY;
                                break;
                            case "overlay":
                                defaultBlendMode = BlendMode.OVERLAY;
                                break;
                            case "screen":
                                defaultBlendMode = BlendMode.SCREEN;
                                break;
                            case "normal":
                            default:
                                defaultBlendMode = BlendMode.NORMAL;
                        }

                        overlays.add(
                            new OverlayConfig(
                                overlay_id,
                                overlay_label,
                                ImageSource.create(ctx.getResources().getIdentifier(overlay_id+"_thumb", "drawable", ctx.getPackageName())),
                                ImageSource.create(ctx.getResources().getIdentifier(overlay_id, "drawable", ctx.getPackageName())),
                                defaultBlendMode,
                                1f
                            )
                        );
                    }
                }

                config.setOverlays(overlays);
            }

            /* Set custom Stickers */
            if( custom.hasKey("stickerCategories") || includeDefaultStickerCategories == false )
            {
                /* Set Default Sticker Category Array */
                ArrayList<StickerListConfigInterface> stickerCats = new ArrayList<StickerListConfigInterface>();

                if(includeDefaultStickerCategories){
                    stickerCats = config.getStickerConfig();
                }


                /* Set Sticker Categories */
                if( custom.hasKey("stickerCategories") ){
                    ReadableArray stickerCatsConfig = custom.getArray("stickerCategories");
                    for (int i = 0; i < stickerCatsConfig.size(); i++) {
                        ReadableMap stickerCat = stickerCatsConfig.getMap(i);
                        String stickerCat_id = stickerCat.getString("id");
                        String stickerCat_label = stickerCat.getString("label");

                        /* Set Stickers */
                        ReadableArray stickersArray = stickerCat.getArray("stickers");
                        ArrayList<StickerConfigInterface> stickers = new ArrayList<StickerConfigInterface>();

                        for (int j = 0; j < stickersArray.size(); j++) {
                            ReadableMap sticker = stickersArray.getMap(j);
                            String sticker_id = sticker.getString("id");

                            String sticker_tint = "none";
                            if(sticker.hasKey("tintMode"))
                                sticker_tint = sticker.getString("tintMode").toLowerCase();

                            String sticker_label = sticker_id;
                            if(sticker.hasKey("label"))
                                sticker_label = sticker.getString("label");

                            ImageStickerConfig.OPTION_MODE tintMode = ImageStickerConfig.OPTION_MODE.NON_OPTIONS;
                            switch(sticker_tint){
                                case "colorized":
                                    tintMode = ImageStickerConfig.OPTION_MODE.INK_STICKER;
                                    break;
                                case "none":
                                default:
                                    tintMode = ImageStickerConfig.OPTION_MODE.NON_OPTIONS;
                            }

                            stickers.add(
                                new ImageStickerConfig(
                                    sticker_id,
                                    sticker_label,
                                    ImageSource.create(ctx.getResources().getIdentifier(sticker_id+"_thumb", "drawable", ctx.getPackageName())),
                                    ImageSource.create(ctx.getResources().getIdentifier(sticker_id, "drawable", ctx.getPackageName())),
                                    tintMode
                                )
                            );
                        }

                        stickerCats.add(
                            new StickerCategoryConfig(
                                stickerCat_label,
                                ImageSource.create(ctx.getResources().getIdentifier(stickerCat_id, "drawable", ctx.getPackageName())),
                                stickers
                            )
                        );
                    }
                }

                config.setStickerLists(stickerCats);
            }

            /* Set custom Brush Colors */
            if( custom.hasKey("brushColors") || includeDefaultBrushColors == false )
            {
                /* Set Default Brush Colors Array */
                ArrayList<ColorConfigInterface> brushColors = new ArrayList<ColorConfigInterface>();

                if(includeDefaultBrushColors){
                    brushColors = config.getBrushColors();
                }


                /* Set Brush Colors */
                if( custom.hasKey("brushColors") ) {
                    ReadableArray brushConfig = custom.getArray("brushColors");
                    for (int i = 0; i < brushConfig.size(); i++) {
                        String brushColor = brushConfig.getString(i).toLowerCase();

                        // Remove #
                        brushColor = brushColor.replace("#", "");

                        // Convert from 3 to 6 char hex
                        if(brushColor.length() == 3){
                            char h1 =  brushColor.charAt(0);
                            char h2 =  brushColor.charAt(1);
                            char h3 =  brushColor.charAt(2);
                            brushColor =    Character.toString(h1) +
                                            Character.toString(h1) +
                                            Character.toString(h2) +
                                            Character.toString(h2) +
                                            Character.toString(h3) +
                                            Character.toString(h3);
                        }

                        int colorInt = 0xff000000 | Integer.parseInt(brushColor, 16);

                        brushColors.add(
                            new ColorConfig(
                                ctx.getResources().getIdentifier("pesdk_react_default_color_name", "string", ctx.getPackageName()),
                                colorInt
                            )
                        );
                    }
                }

                config.setBrushColors(brushColors);
            }

            /* Set custom Sticker Colors */
            if( custom.hasKey("stickerColors") || includeDefaultStickerColors == false )
            {
                /* Set Default Sticker Colors Array */
                ArrayList<ColorConfigInterface> stickerColors = new ArrayList<ColorConfigInterface>();

                if(includeDefaultStickerColors){
                    stickerColors = config.getStickerColorConfig();
                }


                /* Set Sticker Colors */
                if( custom.hasKey("stickerColors") ) {
                    ReadableArray stickerConfig = custom.getArray("stickerColors");
                    for (int i = 0; i < stickerConfig.size(); i++) {
                        String stickerColor = stickerConfig.getString(i).toLowerCase();

                        // Remove #
                        stickerColor = stickerColor.replace("#", "");

                        // Convert from 3 to 6 char hex
                        if(stickerColor.length() == 3){
                            char h1 =  stickerColor.charAt(0);
                            char h2 =  stickerColor.charAt(1);
                            char h3 =  stickerColor.charAt(2);
                            stickerColor =  Character.toString(h1) +
                                            Character.toString(h1) +
                                            Character.toString(h2) +
                                            Character.toString(h2) +
                                            Character.toString(h3) +
                                            Character.toString(h3);
                        }

                        int colorInt = 0xff000000 | Integer.parseInt(stickerColor, 16);

                        stickerColors.add(
                            new ColorConfig(
                                ctx.getResources().getIdentifier("pesdk_react_default_color_name", "string", ctx.getPackageName()),
                                colorInt
                            )
                        );
                    }
                }

                config.setStickerColors(stickerColors);
            }

            if( custom.hasKey("transforms") || includeDefaultTransforms == false )
            {
                /* Set Default Transforms Array */
                ArrayList<AspectConfigInterface> transforms = new ArrayList<AspectConfigInterface>();

                if(includeDefaultTransforms){
                    transforms = config.getAspects();
                } else {
                    transforms.add(CropAspectConfig.FREE_CROP);
                }


                /* Set Sticker Colors */
                if( custom.hasKey("transforms") ) {
                    ReadableArray transformsConfig = custom.getArray("transforms");
                    for (int i = 0; i < transformsConfig.size(); i++) {
                        //String stickerColor = stickerConfig.getString(i).toLowerCase();

                        ReadableMap transform = transformsConfig.getMap(i);
                        String transform_id = transform.getString("id");
                        Integer transform_width = transform.getInt("width");
                        Integer transform_height = transform.getInt("height");
                        String transform_label = transform.getString("label");
                        Boolean transform_rotatable = transform.getBoolean("rotatable");

                        transforms.add(new CropAspectConfig(ctx.getResources().getIdentifier(transform_id, "string", ctx.getPackageName()), transform_width, transform_height));
                    }
                }

                config.setAspects(transforms);
            }

        }

        return settingsList;
    }

    @Override
    public String getName() {
        return "PESDK";
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, java.lang.Object> constants = new HashMap<String, Object>();
        constants.put("transformTool", transformTool);
        constants.put("filterTool", filterTool);
        constants.put("focusTool", focusTool);
        constants.put("adjustTool", adjustTool);
        constants.put("textTool", textTool);
        constants.put("stickerTool", stickerTool);
        constants.put("overlayTool", overlayTool);
        constants.put("brushTool", brushTool);
        constants.put("magic", magic);
        constants.put("backgroundColorCameraKey", backgroundColorCameraKey);
        constants.put("backgroundColorEditorKey", backgroundColorEditorKey);
        constants.put("backgroundColorMenuEditorKey", backgroundColorMenuEditorKey);
        constants.put("cameraRollAllowedKey", cameraRollAllowedKey);
        constants.put("showFiltersInCameraKey", showFiltersInCameraKey);

        return constants;
    }

    @ReactMethod
    public void openEditor(@NonNull String image, ReadableArray features, ReadableMap options, ReadableMap custom, final Promise promise) {
        if (getCurrentActivity() == null) {
           promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity does not exist");
        } else {
            mPESDKPromise = promise;

            SettingsList settingsList = buildConfig(options, features, custom, image.toString());

            new PhotoEditorBuilder(getCurrentActivity())
                    .setSettingsList(settingsList)
                    .startActivityForResult(getCurrentActivity(), RESULT_CODE_PESDK);
        }
    }

    @ReactMethod
    public void openCamera(ReadableArray features, ReadableMap options, ReadableMap custom, final Promise promise) {
        if (getCurrentActivity() == null) {
            promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity does not exist");
        } else {
            mPESDKPromise = promise;

            SettingsList settingsList = buildConfig(options, features, custom, null);

            new CameraPreviewBuilder(getCurrentActivity())
                    .setSettingsList(settingsList)
                    .startActivityForResult(getCurrentActivity(), RESULT_CODE_PESDK);
        }
    }

}
