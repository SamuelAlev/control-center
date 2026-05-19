// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cc_gallery/use_cases/cc_alert_use_cases.dart'
    as _cc_gallery_use_cases_cc_alert_use_cases;
import 'package:cc_gallery/use_cases/cc_autocomplete_use_cases.dart'
    as _cc_gallery_use_cases_cc_autocomplete_use_cases;
import 'package:cc_gallery/use_cases/cc_avatar_use_cases.dart'
    as _cc_gallery_use_cases_cc_avatar_use_cases;
import 'package:cc_gallery/use_cases/cc_badge_use_cases.dart'
    as _cc_gallery_use_cases_cc_badge_use_cases;
import 'package:cc_gallery/use_cases/cc_breadcrumb_use_cases.dart'
    as _cc_gallery_use_cases_cc_breadcrumb_use_cases;
import 'package:cc_gallery/use_cases/cc_button_use_cases.dart'
    as _cc_gallery_use_cases_cc_button_use_cases;
import 'package:cc_gallery/use_cases/cc_card_use_cases.dart'
    as _cc_gallery_use_cases_cc_card_use_cases;
import 'package:cc_gallery/use_cases/cc_checkbox_use_cases.dart'
    as _cc_gallery_use_cases_cc_checkbox_use_cases;
import 'package:cc_gallery/use_cases/cc_chip_use_cases.dart'
    as _cc_gallery_use_cases_cc_chip_use_cases;
import 'package:cc_gallery/use_cases/cc_dialog_use_cases.dart'
    as _cc_gallery_use_cases_cc_dialog_use_cases;
import 'package:cc_gallery/use_cases/cc_divider_use_cases.dart'
    as _cc_gallery_use_cases_cc_divider_use_cases;
import 'package:cc_gallery/use_cases/cc_empty_state_use_cases.dart'
    as _cc_gallery_use_cases_cc_empty_state_use_cases;
import 'package:cc_gallery/use_cases/cc_icon_button_use_cases.dart'
    as _cc_gallery_use_cases_cc_icon_button_use_cases;
import 'package:cc_gallery/use_cases/cc_kbd_use_cases.dart'
    as _cc_gallery_use_cases_cc_kbd_use_cases;
import 'package:cc_gallery/use_cases/cc_menu_use_cases.dart'
    as _cc_gallery_use_cases_cc_menu_use_cases;
import 'package:cc_gallery/use_cases/cc_multi_select_use_cases.dart'
    as _cc_gallery_use_cases_cc_multi_select_use_cases;
import 'package:cc_gallery/use_cases/cc_popover_use_cases.dart'
    as _cc_gallery_use_cases_cc_popover_use_cases;
import 'package:cc_gallery/use_cases/cc_progress_bar_use_cases.dart'
    as _cc_gallery_use_cases_cc_progress_bar_use_cases;
import 'package:cc_gallery/use_cases/cc_radio_use_cases.dart'
    as _cc_gallery_use_cases_cc_radio_use_cases;
import 'package:cc_gallery/use_cases/cc_resizable_use_cases.dart'
    as _cc_gallery_use_cases_cc_resizable_use_cases;
import 'package:cc_gallery/use_cases/cc_select_use_cases.dart'
    as _cc_gallery_use_cases_cc_select_use_cases;
import 'package:cc_gallery/use_cases/cc_sidebar_use_cases.dart'
    as _cc_gallery_use_cases_cc_sidebar_use_cases;
import 'package:cc_gallery/use_cases/cc_spinner_use_cases.dart'
    as _cc_gallery_use_cases_cc_spinner_use_cases;
import 'package:cc_gallery/use_cases/cc_switch_use_cases.dart'
    as _cc_gallery_use_cases_cc_switch_use_cases;
import 'package:cc_gallery/use_cases/cc_tab_view_use_cases.dart'
    as _cc_gallery_use_cases_cc_tab_view_use_cases;
import 'package:cc_gallery/use_cases/cc_tabs_use_cases.dart'
    as _cc_gallery_use_cases_cc_tabs_use_cases;
import 'package:cc_gallery/use_cases/cc_text_area_use_cases.dart'
    as _cc_gallery_use_cases_cc_text_area_use_cases;
import 'package:cc_gallery/use_cases/cc_text_field_use_cases.dart'
    as _cc_gallery_use_cases_cc_text_field_use_cases;
import 'package:cc_gallery/use_cases/cc_text_form_field_use_cases.dart'
    as _cc_gallery_use_cases_cc_text_form_field_use_cases;
import 'package:cc_gallery/use_cases/cc_tile_use_cases.dart'
    as _cc_gallery_use_cases_cc_tile_use_cases;
import 'package:cc_gallery/use_cases/cc_toaster_use_cases.dart'
    as _cc_gallery_use_cases_cc_toaster_use_cases;
import 'package:cc_gallery/use_cases/cc_tooltip_use_cases.dart'
    as _cc_gallery_use_cases_cc_tooltip_use_cases;
import 'package:cc_gallery/use_cases/docs_use_cases.dart'
    as _cc_gallery_use_cases_docs_use_cases;
import 'package:cc_gallery/use_cases/foundation_colors_use_cases.dart'
    as _cc_gallery_use_cases_foundation_colors_use_cases;
import 'package:cc_gallery/use_cases/foundation_metrics_use_cases.dart'
    as _cc_gallery_use_cases_foundation_metrics_use_cases;
import 'package:cc_gallery/use_cases/foundation_motion_use_cases.dart'
    as _cc_gallery_use_cases_foundation_motion_use_cases;
import 'package:cc_gallery/use_cases/foundation_typography_use_cases.dart'
    as _cc_gallery_use_cases_foundation_typography_use_cases;
import 'package:cc_gallery/use_cases/primitive_use_cases.dart'
    as _cc_gallery_use_cases_primitive_use_cases;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Components',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Buttons',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Loading',
                builder: _cc_gallery_use_cases_cc_button_use_cases
                    .ccButtonLoadingUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_button_use_cases
                    .ccButtonPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder: _cc_gallery_use_cases_cc_button_use_cases
                    .ccButtonSizesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Variants',
                builder: _cc_gallery_use_cases_cc_button_use_cases
                    .ccButtonVariantsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcIconButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Active color',
                builder: _cc_gallery_use_cases_cc_icon_button_use_cases
                    .ccIconButtonActiveColorUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_icon_button_use_cases
                    .ccIconButtonPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder: _cc_gallery_use_cases_cc_icon_button_use_cases
                    .ccIconButtonSizesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Variants',
                builder: _cc_gallery_use_cases_cc_icon_button_use_cases
                    .ccIconButtonVariantsUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Containers',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcAvatar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Custom background',
                builder: _cc_gallery_use_cases_cc_avatar_use_cases
                    .ccAvatarBackgroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Fallback content',
                builder: _cc_gallery_use_cases_cc_avatar_use_cases
                    .ccAvatarFallbackUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_avatar_use_cases
                    .ccAvatarPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder: _cc_gallery_use_cases_cc_avatar_use_cases
                    .ccAvatarSizesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Interactive',
                builder: _cc_gallery_use_cases_cc_card_use_cases
                    .ccCardInteractiveUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Padding',
                builder: _cc_gallery_use_cases_cc_card_use_cases
                    .ccCardPaddingUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_card_use_cases
                    .ccCardPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Surfaces',
                builder: _cc_gallery_use_cases_cc_card_use_cases
                    .ccCardSurfacesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcChip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Deletable',
                builder: _cc_gallery_use_cases_cc_chip_use_cases
                    .ccChipDeletableUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_chip_use_cases
                    .ccChipPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder:
                    _cc_gallery_use_cases_cc_chip_use_cases.ccChipStatesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icon',
                builder: _cc_gallery_use_cases_cc_chip_use_cases
                    .ccChipWithIconUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcDivider',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Horizontal',
                builder: _cc_gallery_use_cases_cc_divider_use_cases
                    .ccDividerHorizontalUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_divider_use_cases
                    .ccDividerPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Thickness & indent',
                builder: _cc_gallery_use_cases_cc_divider_use_cases
                    .ccDividerThicknessIndentUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Vertical',
                builder: _cc_gallery_use_cases_cc_divider_use_cases
                    .ccDividerVerticalUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcEmptyState',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Message only',
                builder: _cc_gallery_use_cases_cc_empty_state_use_cases
                    .ccEmptyStateMessageOnlyUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_empty_state_use_cases
                    .ccEmptyStatePlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With action',
                builder: _cc_gallery_use_cases_cc_empty_state_use_cases
                    .ccEmptyStateWithActionUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With description',
                builder: _cc_gallery_use_cases_cc_empty_state_use_cases
                    .ccEmptyStateWithDescriptionUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcKbd',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _cc_gallery_use_cases_cc_kbd_use_cases.ccKbdDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_kbd_use_cases
                    .ccKbdPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Shortcut vocabulary',
                builder: _cc_gallery_use_cases_cc_kbd_use_cases
                    .ccKbdVocabularyUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder:
                    _cc_gallery_use_cases_cc_kbd_use_cases.ccKbdSizesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTile',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Anatomy',
                builder: _cc_gallery_use_cases_cc_tile_use_cases
                    .ccTileAnatomyUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Navigation list',
                builder: _cc_gallery_use_cases_cc_tile_use_cases
                    .ccTileNavigationListUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_tile_use_cases
                    .ccTilePlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder:
                    _cc_gallery_use_cases_cc_tile_use_cases.ccTileStatesUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Feedback',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcAlert',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_alert_use_cases
                    .ccAlertPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Title and description',
                builder: _cc_gallery_use_cases_cc_alert_use_cases
                    .ccAlertTitleAndDescriptionUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Variants',
                builder: _cc_gallery_use_cases_cc_alert_use_cases
                    .ccAlertVariantsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With and without icon',
                builder: _cc_gallery_use_cases_cc_alert_use_cases
                    .ccAlertWithIconUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcBadge',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_badge_use_cases
                    .ccBadgePlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Variants',
                builder: _cc_gallery_use_cases_cc_badge_use_cases
                    .ccBadgeVariantsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icon',
                builder: _cc_gallery_use_cases_cc_badge_use_cases
                    .ccBadgeWithIconUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcProgressBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Determinate',
                builder: _cc_gallery_use_cases_cc_progress_bar_use_cases
                    .ccProgressBarDeterminateUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Heights',
                builder: _cc_gallery_use_cases_cc_progress_bar_use_cases
                    .ccProgressBarHeightsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Indeterminate',
                builder: _cc_gallery_use_cases_cc_progress_bar_use_cases
                    .ccProgressBarIndeterminateUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_progress_bar_use_cases
                    .ccProgressBarPlaygroundUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcSpinner',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Colors',
                builder: _cc_gallery_use_cases_cc_spinner_use_cases
                    .ccSpinnerColorsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_spinner_use_cases
                    .ccSpinnerPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder: _cc_gallery_use_cases_cc_spinner_use_cases
                    .ccSpinnerSizesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Stroke widths',
                builder: _cc_gallery_use_cases_cc_spinner_use_cases
                    .ccSpinnerStrokeWidthsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcToastScope',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Alignments',
                builder: _cc_gallery_use_cases_cc_toaster_use_cases
                    .ccToasterAlignmentsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_toaster_use_cases
                    .ccToasterPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Variants',
                builder: _cc_gallery_use_cases_cc_toaster_use_cases
                    .ccToasterVariantsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTooltip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_tooltip_use_cases
                    .ccTooltipDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Long and short',
                builder: _cc_gallery_use_cases_cc_tooltip_use_cases
                    .ccTooltipLongAndShortUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_tooltip_use_cases
                    .ccTooltipPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Rich content',
                builder: _cc_gallery_use_cases_cc_tooltip_use_cases
                    .ccTooltipRichContentUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Inputs',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcAutocomplete',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_autocomplete_use_cases
                    .ccAutocompleteDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Disabled',
                builder: _cc_gallery_use_cases_cc_autocomplete_use_cases
                    .ccAutocompleteDisabledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_autocomplete_use_cases
                    .ccAutocompletePlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icons',
                builder: _cc_gallery_use_cases_cc_autocomplete_use_cases
                    .ccAutocompleteWithIconsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcCheckbox',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Checklist',
                builder: _cc_gallery_use_cases_cc_checkbox_use_cases
                    .ccCheckboxChecklistUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_checkbox_use_cases
                    .ccCheckboxPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder: _cc_gallery_use_cases_cc_checkbox_use_cases
                    .ccCheckboxStatesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcMultiSelect',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Chips summary',
                builder: _cc_gallery_use_cases_cc_multi_select_use_cases
                    .ccMultiSelectChipsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Count summary',
                builder: _cc_gallery_use_cases_cc_multi_select_use_cases
                    .ccMultiSelectCountUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Disabled',
                builder: _cc_gallery_use_cases_cc_multi_select_use_cases
                    .ccMultiSelectDisabledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_multi_select_use_cases
                    .ccMultiSelectPlaygroundUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcRadio',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Group',
                builder: _cc_gallery_use_cases_cc_radio_use_cases
                    .ccRadioGroupUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_radio_use_cases
                    .ccRadioPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder: _cc_gallery_use_cases_cc_radio_use_cases
                    .ccRadioStatesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcSelect',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_select_use_cases
                    .ccSelectDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Empty & disabled',
                builder: _cc_gallery_use_cases_cc_select_use_cases
                    .ccSelectEmptyAndDisabledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_select_use_cases
                    .ccSelectPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icons',
                builder: _cc_gallery_use_cases_cc_select_use_cases
                    .ccSelectWithIconsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcSwitch',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_switch_use_cases
                    .ccSwitchPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Setting row',
                builder: _cc_gallery_use_cases_cc_switch_use_cases
                    .ccSwitchSettingRowUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder: _cc_gallery_use_cases_cc_switch_use_cases
                    .ccSwitchStatesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTextArea',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Empty and filled',
                builder: _cc_gallery_use_cases_cc_text_area_use_cases
                    .ccTextAreaEmptyAndFilledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Error and disabled',
                builder: _cc_gallery_use_cases_cc_text_area_use_cases
                    .ccTextAreaErrorAndDisabledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_text_area_use_cases
                    .ccTextAreaPlaygroundUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTextField',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_text_field_use_cases
                    .ccTextFieldPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Prefix and suffix',
                builder: _cc_gallery_use_cases_cc_text_field_use_cases
                    .ccTextFieldAffordancesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sizes',
                builder: _cc_gallery_use_cases_cc_text_field_use_cases
                    .ccTextFieldSizesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder: _cc_gallery_use_cases_cc_text_field_use_cases
                    .ccTextFieldStatesUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTextFormField',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_text_form_field_use_cases
                    .ccTextFormFieldPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'States',
                builder: _cc_gallery_use_cases_cc_text_form_field_use_cases
                    .ccTextFormFieldStatesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Validation',
                builder: _cc_gallery_use_cases_cc_text_form_field_use_cases
                    .ccTextFormFieldValidationUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With affordances',
                builder: _cc_gallery_use_cases_cc_text_form_field_use_cases
                    .ccTextFormFieldAffordancesUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Layout',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcResizable',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Horizontal split',
                builder: _cc_gallery_use_cases_cc_resizable_use_cases
                    .ccResizableHorizontalUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_resizable_use_cases
                    .ccResizablePlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Three regions',
                builder: _cc_gallery_use_cases_cc_resizable_use_cases
                    .ccResizableThreeUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Vertical split',
                builder: _cc_gallery_use_cases_cc_resizable_use_cases
                    .ccResizableVerticalUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Navigation & Overlays',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CcBreadcrumb',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_breadcrumb_use_cases
                    .ccBreadcrumbDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Depths',
                builder: _cc_gallery_use_cases_cc_breadcrumb_use_cases
                    .ccBreadcrumbDepthsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_breadcrumb_use_cases
                    .ccBreadcrumbPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icons',
                builder: _cc_gallery_use_cases_cc_breadcrumb_use_cases
                    .ccBreadcrumbWithIconsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcDialog',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Confirm',
                builder: _cc_gallery_use_cases_cc_dialog_use_cases
                    .ccDialogConfirmUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Content only',
                builder: _cc_gallery_use_cases_cc_dialog_use_cases
                    .ccDialogContentOnlyUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_dialog_use_cases
                    .ccDialogPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Wide single action',
                builder: _cc_gallery_use_cases_cc_dialog_use_cases
                    .ccDialogWideUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcMenu',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Plain and disabled',
                builder:
                    _cc_gallery_use_cases_cc_menu_use_cases.ccMenuPlainUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_menu_use_cases
                    .ccMenuPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Workspace actions',
                builder: _cc_gallery_use_cases_cc_menu_use_cases
                    .ccMenuActionsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcPopover',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Controller driven',
                builder: _cc_gallery_use_cases_cc_popover_use_cases
                    .ccPopoverControllerUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_popover_use_cases
                    .ccPopoverDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Match target width',
                builder: _cc_gallery_use_cases_cc_popover_use_cases
                    .ccPopoverMatchWidthUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_popover_use_cases
                    .ccPopoverPlaygroundUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcSidebar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Collapsed rail',
                builder: _cc_gallery_use_cases_cc_sidebar_use_cases
                    .ccSidebarCollapsedUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Collapsible groups',
                builder: _cc_gallery_use_cases_cc_sidebar_use_cases
                    .ccSidebarCollapsibleGroupsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Expanded',
                builder: _cc_gallery_use_cases_cc_sidebar_use_cases
                    .ccSidebarExpandedUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_sidebar_use_cases
                    .ccSidebarPlaygroundUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTabView',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Icon labels',
                builder: _cc_gallery_use_cases_cc_tab_view_use_cases
                    .ccTabViewIconLabelsUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_tab_view_use_cases
                    .ccTabViewPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Scrollable strip',
                builder: _cc_gallery_use_cases_cc_tab_view_use_cases
                    .ccTabViewScrollableUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Text labels',
                builder: _cc_gallery_use_cases_cc_tab_view_use_cases
                    .ccTabViewTextLabelsUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CcTabs',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _cc_gallery_use_cases_cc_tabs_use_cases
                    .ccTabsDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Playground',
                builder: _cc_gallery_use_cases_cc_tabs_use_cases
                    .ccTabsPlaygroundUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Two tabs',
                builder:
                    _cc_gallery_use_cases_cc_tabs_use_cases.ccTabsTwoUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With icons',
                builder: _cc_gallery_use_cases_cc_tabs_use_cases
                    .ccTabsWithIconsUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookCategory(
    name: 'Docs',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'Principles',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Principles',
            builder: _cc_gallery_use_cases_docs_use_cases.principlesUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'Theming',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Theming',
            builder: _cc_gallery_use_cases_docs_use_cases.themingUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'Usage',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Usage',
            builder: _cc_gallery_use_cases_docs_use_cases.usageUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'Welcome',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Welcome',
            builder: _cc_gallery_use_cases_docs_use_cases.welcomeUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookCategory(
    name: 'Foundations',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Primitives',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'FocusRing',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Focused field',
                builder:
                    _cc_gallery_use_cases_primitive_use_cases.focusRingUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SegmentedToggle',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Write / Preview',
                builder: _cc_gallery_use_cases_primitive_use_cases
                    .segmentedToggleUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Tokens',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ColorTokens',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Roles & scale',
                builder: _cc_gallery_use_cases_foundation_colors_use_cases
                    .colorRolesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Semantic palette',
                builder: _cc_gallery_use_cases_foundation_colors_use_cases
                    .colorSemanticUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'ElevationScale',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Shadows',
                builder: _cc_gallery_use_cases_foundation_metrics_use_cases
                    .elevationScaleUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'MotionSpecimen',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Durations & curves',
                builder: _cc_gallery_use_cases_foundation_motion_use_cases
                    .motionSpecimenUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'RadiusScale',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Scale',
                builder: _cc_gallery_use_cases_foundation_metrics_use_cases
                    .radiusScaleUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SpacingScale',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Scale',
                builder: _cc_gallery_use_cases_foundation_metrics_use_cases
                    .spacingScaleUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'TypeScale',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Type scale',
                builder: _cc_gallery_use_cases_foundation_typography_use_cases
                    .typeScaleUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
