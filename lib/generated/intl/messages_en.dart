// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(value, unit) => "Depth: ${value} ${unit}";

  static String m1(ply, surface) => "Ply ${ply} · ${surface}";

  static String m2(name) => "\"${name}\" will be removed from your library.";

  static String m3(name) => "Delete ${name}";

  static String m4(angles) => "Angles: ${angles}";

  static String m5(shown, total) =>
      "${shown} of ${total} surfaces shown. Exports include all surfaces.";

  static String m6(ply, surface) => "Selected surface: ply ${ply}, ${surface}";

  static String m7(units) =>
      "Values fill in as ${units}. Typical published data for preliminary design; check your supplier data sheets.";

  static String m8(kind) => "${kind} library";

  static String m9(name) => "Saved \"${name}\" to your library.";

  static String m10(unit) => "Too large for ${unit}; check units";

  static String m11(count) => "+${count} more";

  static String m12(count) =>
      "${Intl.plural(count, one: '1 ply', other: '${count} plies')}";

  static String m13(name) =>
      "A saved material named \"${name}\" already exists. Replace its saved values or choose another name.";

  static String m14(value, unit) => "Total thickness: ${value} ${unit}";

  static String m15(modulus, stress, length, loads) =>
      "Moduli ${modulus} · stress ${stress} · length ${length} · loads ${loads}";

  static String m16(question) => "Ask: ${question}";

  static String m17(count) =>
      "${Intl.plural(count, one: '${count} attachment', other: '${count} attachments')}";

  static String m18(language) => "${language} - streaming";

  static String m19(name) => "Delete “${name}”? This cannot be undone.";

  static String m20(count) => "${count} files";

  static String m21(dateTime) => "Message time: ${dateTime}";

  static String m22(name) => "Preview ${name}";

  static String m23(error) => "Processing failed: ${error}";

  static String m24(name) => "Read ${name}";

  static String m25(name) => "Remove ${name}";

  static String m26(query) => "Search \"${query}\"";

  static String m27(count) => "${count} matching messages";

  static String m28(name) => "Welcome, ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage(
      "Angle of Rotation",
    ),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage(
      "Anisotropic material",
    ),
    "Area": MessageLookupByLibrary.simpleMessage("Area"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("Buckling Load"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage(
      "Buckling load of column",
    ),
    "Calculate": MessageLookupByLibrary.simpleMessage("Calculate"),
    "Calculator_all_failure_criteria": MessageLookupByLibrary.simpleMessage(
      "All criteria",
    ),
    "Calculator_apply_material": MessageLookupByLibrary.simpleMessage(
      "Apply material",
    ),
    "Calculator_built_in_materials": MessageLookupByLibrary.simpleMessage(
      "Built-in",
    ),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "Could not calculate these results. Check the material constants, loads and thickness.",
    ),
    "Calculator_chart_depth": m0,
    "Calculator_chart_inspection_hint": MessageLookupByLibrary.simpleMessage(
      "Tap a point or hover to inspect ply values",
    ),
    "Calculator_chart_ply_surface": m1,
    "Calculator_choose_another_name": MessageLookupByLibrary.simpleMessage(
      "Choose another name",
    ),
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage(
      "Clear layup sequence",
    ),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy these results. Please try again.",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage(
      "Copy results",
    ),
    "Calculator_delete_material_message": m2,
    "Calculator_delete_material_title": MessageLookupByLibrary.simpleMessage(
      "Delete material?",
    ),
    "Calculator_delete_material_tooltip": m3,
    "Calculator_expanded_angles": m4,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage(
      "Could not export these results.",
    ),
    "Calculator_export_materials": MessageLookupByLibrary.simpleMessage(
      "Export my materials (JSON)",
    ),
    "Calculator_export_materials_help": MessageLookupByLibrary.simpleMessage(
      "Exports all saved materials in SI units, including materials outside the current search.",
    ),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage(
      "Export results",
    ),
    "Calculator_failed_surfaces_only": MessageLookupByLibrary.simpleMessage(
      "Failing surfaces only",
    ),
    "Calculator_failure_criterion": MessageLookupByLibrary.simpleMessage(
      "Criterion",
    ),
    "Calculator_failure_exports_all": MessageLookupByLibrary.simpleMessage(
      "Exports always include every surface and criterion.",
    ),
    "Calculator_failure_filter_summary": m5,
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "Enter a finite number",
    ),
    "Calculator_focused_surface": m6,
    "Calculator_library": MessageLookupByLibrary.simpleMessage("Library"),
    "Calculator_material_alphabetical_order":
        MessageLookupByLibrary.simpleMessage("Name (A–Z)"),
    "Calculator_material_delete_failed": MessageLookupByLibrary.simpleMessage(
      "Could not delete this material. Please try again.",
    ),
    "Calculator_material_details": MessageLookupByLibrary.simpleMessage(
      "Material details",
    ),
    "Calculator_material_elastic_properties":
        MessageLookupByLibrary.simpleMessage("Elastic properties"),
    "Calculator_material_elastic_required":
        MessageLookupByLibrary.simpleMessage(
          "Enter the elastic constants before saving.",
        ),
    "Calculator_material_export_empty": MessageLookupByLibrary.simpleMessage(
      "Save a custom material to enable JSON export.",
    ),
    "Calculator_material_export_failed": MessageLookupByLibrary.simpleMessage(
      "Could not export saved materials. Please try again.",
    ),
    "Calculator_material_kind_fiber": MessageLookupByLibrary.simpleMessage(
      "Fiber",
    ),
    "Calculator_material_kind_lamina": MessageLookupByLibrary.simpleMessage(
      "Unidirectional lamina",
    ),
    "Calculator_material_kind_matrix": MessageLookupByLibrary.simpleMessage(
      "Matrix",
    ),
    "Calculator_material_library_help": m7,
    "Calculator_material_library_title": m8,
    "Calculator_material_missing_note": MessageLookupByLibrary.simpleMessage(
      "Missing elastic values keep the current inputs. Missing thermal or strength groups also keep the current inputs.",
    ),
    "Calculator_material_name": MessageLookupByLibrary.simpleMessage(
      "Material name",
    ),
    "Calculator_material_not_provided": MessageLookupByLibrary.simpleMessage(
      "Not provided",
    ),
    "Calculator_material_order": MessageLookupByLibrary.simpleMessage("Order"),
    "Calculator_material_original_order": MessageLookupByLibrary.simpleMessage(
      "Original order",
    ),
    "Calculator_material_save_failed": MessageLookupByLibrary.simpleMessage(
      "Could not save this material. Check its values and try again.",
    ),
    "Calculator_material_saved": m9,
    "Calculator_material_source": MessageLookupByLibrary.simpleMessage(
      "Source",
    ),
    "Calculator_material_strengths": MessageLookupByLibrary.simpleMessage(
      "Strengths",
    ),
    "Calculator_material_strengths_note": MessageLookupByLibrary.simpleMessage(
      "Strengths are applied together only when all five values are provided.",
    ),
    "Calculator_material_thermal_note": MessageLookupByLibrary.simpleMessage(
      "Thermal values need α11 (α for isotropic materials). For laminae and fibers, missing α22 uses α11 and shear CTE is set to zero.",
    ),
    "Calculator_material_thermal_properties":
        MessageLookupByLibrary.simpleMessage("Thermal expansion"),
    "Calculator_material_type": MessageLookupByLibrary.simpleMessage(
      "Material type",
    ),
    "Calculator_modulus_too_large": m10,
    "Calculator_more_plies": m11,
    "Calculator_my_materials": MessageLookupByLibrary.simpleMessage(
      "My materials",
    ),
    "Calculator_no_failed_surfaces": MessageLookupByLibrary.simpleMessage(
      "No failing surfaces match this criterion.",
    ),
    "Calculator_no_failure_results": MessageLookupByLibrary.simpleMessage(
      "No failure results are available.",
    ),
    "Calculator_no_material_matches": MessageLookupByLibrary.simpleMessage(
      "No materials match your search.",
    ),
    "Calculator_ply_count": m12,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "Must be between -1 and 0.5",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage(
      "Must be greater than zero",
    ),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "Thickness must be greater than zero",
    ),
    "Calculator_replace_material": MessageLookupByLibrary.simpleMessage(
      "Replace",
    ),
    "Calculator_replace_material_message": m13,
    "Calculator_replace_material_title": MessageLookupByLibrary.simpleMessage(
      "Replace saved material?",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "Results copied to clipboard",
    ),
    "Calculator_save_current_material": MessageLookupByLibrary.simpleMessage(
      "Save current inputs as a material",
    ),
    "Calculator_save_material_title": MessageLookupByLibrary.simpleMessage(
      "Save material",
    ),
    "Calculator_search_materials": MessageLookupByLibrary.simpleMessage(
      "Search materials",
    ),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage(
      "Share as CSV",
    ),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage(
      "Share as PDF",
    ),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("SI"),
    "Calculator_surface_bottom": MessageLookupByLibrary.simpleMessage("Bottom"),
    "Calculator_surface_top": MessageLookupByLibrary.simpleMessage("Top"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("Thickness"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "Too many layers",
    ),
    "Calculator_total_thickness": m14,
    "Calculator_unit_details": m15,
    "Calculator_units": MessageLookupByLibrary.simpleMessage(
      "Calculator units",
    ),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "Inputs, results and exports use these units. Values you have already typed are not converted.",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("US customary"),
    "Calculator_view_in_table": MessageLookupByLibrary.simpleMessage(
      "View in table",
    ),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "Must be between 0 and 1",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage(
      "Wrong layup sequence",
    ),
    "Chat_account_settings": MessageLookupByLibrary.simpleMessage(
      "Account & settings",
    ),
    "Chat_add_attachment": MessageLookupByLibrary.simpleMessage(
      "Add attachment",
    ),
    "Chat_archive": MessageLookupByLibrary.simpleMessage("Archive"),
    "Chat_archived": MessageLookupByLibrary.simpleMessage("Archived"),
    "Chat_ask_question": m16,
    "Chat_attach_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "Attach RAG sources",
    ),
    "Chat_attachment_count": m17,
    "Chat_bad_response": MessageLookupByLibrary.simpleMessage("Bad response"),
    "Chat_camera": MessageLookupByLibrary.simpleMessage("Camera"),
    "Chat_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "Chat_chat_options": MessageLookupByLibrary.simpleMessage("Chat options"),
    "Chat_chat_title": MessageLookupByLibrary.simpleMessage("Title"),
    "Chat_chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "Chat_clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "Chat_clear_draft": MessageLookupByLibrary.simpleMessage("Clear draft"),
    "Chat_clear_search": MessageLookupByLibrary.simpleMessage("Clear search"),
    "Chat_close_image_preview": MessageLookupByLibrary.simpleMessage(
      "Close image preview",
    ),
    "Chat_code": MessageLookupByLibrary.simpleMessage("code"),
    "Chat_code_copy_failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy this code.",
    ),
    "Chat_code_streaming": m18,
    "Chat_collapse_answer": MessageLookupByLibrary.simpleMessage(
      "Collapse answer",
    ),
    "Chat_composer_done": MessageLookupByLibrary.simpleMessage("Done"),
    "Chat_composer_hint": MessageLookupByLibrary.simpleMessage(
      "Ask about composites engineering…",
    ),
    "Chat_composite_calculators": MessageLookupByLibrary.simpleMessage(
      "Composite Calculators",
    ),
    "Chat_composite_expert": MessageLookupByLibrary.simpleMessage(
      "Composite expert",
    ),
    "Chat_copied": MessageLookupByLibrary.simpleMessage("Copied"),
    "Chat_copy_code": MessageLookupByLibrary.simpleMessage("Copy code"),
    "Chat_copy_exchange": MessageLookupByLibrary.simpleMessage(
      "Copy question and answer",
    ),
    "Chat_copy_link": MessageLookupByLibrary.simpleMessage("Copy link"),
    "Chat_copy_message": MessageLookupByLibrary.simpleMessage("Copy message"),
    "Chat_delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "Chat_delete_chat_message": m19,
    "Chat_delete_chat_title": MessageLookupByLibrary.simpleMessage(
      "Delete chat?",
    ),
    "Chat_delete_untitled_chat_message": MessageLookupByLibrary.simpleMessage(
      "Delete this chat? This cannot be undone.",
    ),
    "Chat_draft": MessageLookupByLibrary.simpleMessage("Draft"),
    "Chat_draft_cleared": MessageLookupByLibrary.simpleMessage(
      "Draft cleared.",
    ),
    "Chat_edit_negative_feedback": MessageLookupByLibrary.simpleMessage(
      "Edit negative feedback",
    ),
    "Chat_edit_positive_feedback": MessageLookupByLibrary.simpleMessage(
      "Edit positive feedback",
    ),
    "Chat_engineering_copilot": MessageLookupByLibrary.simpleMessage(
      "Composites engineering copilot",
    ),
    "Chat_exchange_answer": MessageLookupByLibrary.simpleMessage("Answer"),
    "Chat_exchange_copied": MessageLookupByLibrary.simpleMessage(
      "Question and answer copied",
    ),
    "Chat_exchange_copy_failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy this exchange.",
    ),
    "Chat_exchange_question": MessageLookupByLibrary.simpleMessage("Question"),
    "Chat_expand_answer": MessageLookupByLibrary.simpleMessage("Expand answer"),
    "Chat_expand_composer": MessageLookupByLibrary.simpleMessage(
      "Expand composer",
    ),
    "Chat_expanded_composer": MessageLookupByLibrary.simpleMessage(
      "Edit question",
    ),
    "Chat_export_conversation": MessageLookupByLibrary.simpleMessage(
      "Export conversation",
    ),
    "Chat_export_failed": MessageLookupByLibrary.simpleMessage(
      "Could not export this conversation.",
    ),
    "Chat_feedback_accurate": MessageLookupByLibrary.simpleMessage("Accurate"),
    "Chat_feedback_additional_details": MessageLookupByLibrary.simpleMessage(
      "Additional details",
    ),
    "Chat_feedback_clear_explanation": MessageLookupByLibrary.simpleMessage(
      "Clear explanation",
    ),
    "Chat_feedback_did_not_follow": MessageLookupByLibrary.simpleMessage(
      "Didn\'t follow instructions",
    ),
    "Chat_feedback_excellent": MessageLookupByLibrary.simpleMessage(
      "10 · Excellent",
    ),
    "Chat_feedback_followed_instructions": MessageLookupByLibrary.simpleMessage(
      "Followed instructions",
    ),
    "Chat_feedback_good_structure": MessageLookupByLibrary.simpleMessage(
      "Good structure",
    ),
    "Chat_feedback_help": MessageLookupByLibrary.simpleMessage(
      "Your feedback helps improve answer quality.",
    ),
    "Chat_feedback_helpful": MessageLookupByLibrary.simpleMessage("Helpful"),
    "Chat_feedback_inaccurate": MessageLookupByLibrary.simpleMessage(
      "Inaccurate",
    ),
    "Chat_feedback_needs_work": MessageLookupByLibrary.simpleMessage(
      "Needs work",
    ),
    "Chat_feedback_not_useful": MessageLookupByLibrary.simpleMessage(
      "Not useful",
    ),
    "Chat_feedback_optional": MessageLookupByLibrary.simpleMessage("Optional"),
    "Chat_feedback_other": MessageLookupByLibrary.simpleMessage("Other"),
    "Chat_feedback_poor": MessageLookupByLibrary.simpleMessage("1 · Poor"),
    "Chat_feedback_quality_score": MessageLookupByLibrary.simpleMessage(
      "Quality score",
    ),
    "Chat_feedback_reason_prompt": MessageLookupByLibrary.simpleMessage(
      "What influenced your rating?",
    ),
    "Chat_feedback_reason_required": MessageLookupByLibrary.simpleMessage(
      "Select at least one reason to continue.",
    ),
    "Chat_feedback_save_failed": MessageLookupByLibrary.simpleMessage(
      "Feedback could not be saved. Try again.",
    ),
    "Chat_feedback_saved": MessageLookupByLibrary.simpleMessage(
      "Feedback saved.",
    ),
    "Chat_feedback_submit": MessageLookupByLibrary.simpleMessage(
      "Submit feedback",
    ),
    "Chat_feedback_submitted": MessageLookupByLibrary.simpleMessage(
      "Feedback submitted",
    ),
    "Chat_feedback_title": MessageLookupByLibrary.simpleMessage(
      "Rate this response",
    ),
    "Chat_feedback_too_verbose": MessageLookupByLibrary.simpleMessage(
      "Too verbose",
    ),
    "Chat_feedback_unclear": MessageLookupByLibrary.simpleMessage("Unclear"),
    "Chat_feedback_update": MessageLookupByLibrary.simpleMessage(
      "Update feedback",
    ),
    "Chat_feedback_useful_detail": MessageLookupByLibrary.simpleMessage(
      "Useful detail",
    ),
    "Chat_file_count": m20,
    "Chat_files": MessageLookupByLibrary.simpleMessage("Files"),
    "Chat_find_in_chat": MessageLookupByLibrary.simpleMessage("Find in chat"),
    "Chat_folder_name": MessageLookupByLibrary.simpleMessage("Folder name"),
    "Chat_generating_response_stop": MessageLookupByLibrary.simpleMessage(
      "Generating response. Stop generating",
    ),
    "Chat_get_response": MessageLookupByLibrary.simpleMessage("Get response"),
    "Chat_good_response": MessageLookupByLibrary.simpleMessage("Good response"),
    "Chat_image_preview": MessageLookupByLibrary.simpleMessage("Image preview"),
    "Chat_image_preview_unavailable": MessageLookupByLibrary.simpleMessage(
      "Image preview is unavailable.",
    ),
    "Chat_jump_to_latest": MessageLookupByLibrary.simpleMessage(
      "Jump to latest",
    ),
    "Chat_knowledge": MessageLookupByLibrary.simpleMessage("Knowledge"),
    "Chat_knowledge_collection": MessageLookupByLibrary.simpleMessage(
      "Knowledge collection",
    ),
    "Chat_knowledge_file": MessageLookupByLibrary.simpleMessage(
      "Knowledge file",
    ),
    "Chat_link_copied": MessageLookupByLibrary.simpleMessage(
      "Link copied to clipboard",
    ),
    "Chat_message_time": m21,
    "Chat_models": MessageLookupByLibrary.simpleMessage("Models"),
    "Chat_more": MessageLookupByLibrary.simpleMessage("More"),
    "Chat_more_actions": MessageLookupByLibrary.simpleMessage("More actions"),
    "Chat_move_to_folder": MessageLookupByLibrary.simpleMessage(
      "Move to folder",
    ),
    "Chat_new_chat": MessageLookupByLibrary.simpleMessage("New chat"),
    "Chat_new_folder": MessageLookupByLibrary.simpleMessage("New folder"),
    "Chat_no_chats": MessageLookupByLibrary.simpleMessage("No chats yet"),
    "Chat_no_chats_found": MessageLookupByLibrary.simpleMessage(
      "No chats found",
    ),
    "Chat_no_folder_chats": MessageLookupByLibrary.simpleMessage(
      "No chats in folder",
    ),
    "Chat_no_folders": MessageLookupByLibrary.simpleMessage("No folders yet"),
    "Chat_no_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "No knowledge sources found",
    ),
    "Chat_no_matching_chats": MessageLookupByLibrary.simpleMessage(
      "No matching chats",
    ),
    "Chat_open_calculators": MessageLookupByLibrary.simpleMessage(
      "Open Composite Calculators",
    ),
    "Chat_open_link_failed": MessageLookupByLibrary.simpleMessage(
      "Could not open this link.",
    ),
    "Chat_photo_library": MessageLookupByLibrary.simpleMessage("Photo Library"),
    "Chat_pin": MessageLookupByLibrary.simpleMessage("Pin"),
    "Chat_pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "Chat_preview_image": m22,
    "Chat_processing_document": MessageLookupByLibrary.simpleMessage(
      "Processing document…",
    ),
    "Chat_processing_failed": MessageLookupByLibrary.simpleMessage(
      "Processing failed",
    ),
    "Chat_processing_failed_detail": m23,
    "Chat_read_file": m24,
    "Chat_refresh_knowledge": MessageLookupByLibrary.simpleMessage(
      "Refresh knowledge",
    ),
    "Chat_regenerate_response": MessageLookupByLibrary.simpleMessage(
      "Regenerate response",
    ),
    "Chat_remove_attachment": m25,
    "Chat_remove_from_folder": MessageLookupByLibrary.simpleMessage(
      "Remove from folder",
    ),
    "Chat_rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "Chat_rename_chat": MessageLookupByLibrary.simpleMessage("Rename chat"),
    "Chat_replace_draft": MessageLookupByLibrary.simpleMessage("Replace draft"),
    "Chat_replace_draft_message": MessageLookupByLibrary.simpleMessage(
      "Replace the current unsent text with this message?",
    ),
    "Chat_replace_draft_title": MessageLookupByLibrary.simpleMessage(
      "Replace draft?",
    ),
    "Chat_response_interrupted": MessageLookupByLibrary.simpleMessage(
      "Response interrupted",
    ),
    "Chat_save": MessageLookupByLibrary.simpleMessage("Save"),
    "Chat_search_all": MessageLookupByLibrary.simpleMessage("All"),
    "Chat_search_answers": MessageLookupByLibrary.simpleMessage("Answers"),
    "Chat_search_assistant": MessageLookupByLibrary.simpleMessage("Assistant"),
    "Chat_search_chats": MessageLookupByLibrary.simpleMessage("Search chats"),
    "Chat_search_clear": MessageLookupByLibrary.simpleMessage("Clear search"),
    "Chat_search_copy_excerpt": MessageLookupByLibrary.simpleMessage(
      "Copy excerpt",
    ),
    "Chat_search_copy_failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy this excerpt.",
    ),
    "Chat_search_empty": MessageLookupByLibrary.simpleMessage(
      "Enter text to search this conversation.",
    ),
    "Chat_search_excerpt_copied": MessageLookupByLibrary.simpleMessage(
      "Excerpt copied",
    ),
    "Chat_search_history_title": m26,
    "Chat_search_knowledge": MessageLookupByLibrary.simpleMessage(
      "Search knowledge",
    ),
    "Chat_search_loaded_messages": MessageLookupByLibrary.simpleMessage(
      "Search loaded messages",
    ),
    "Chat_search_match_count": m27,
    "Chat_search_no_matches": MessageLookupByLibrary.simpleMessage(
      "No matching messages.",
    ),
    "Chat_search_questions": MessageLookupByLibrary.simpleMessage("Questions"),
    "Chat_search_you": MessageLookupByLibrary.simpleMessage("You"),
    "Chat_select_model": MessageLookupByLibrary.simpleMessage("Select model"),
    "Chat_send_message": MessageLookupByLibrary.simpleMessage("Send message"),
    "Chat_share": MessageLookupByLibrary.simpleMessage("Share"),
    "Chat_share_chat": MessageLookupByLibrary.simpleMessage("Share chat"),
    "Chat_share_chat_description": MessageLookupByLibrary.simpleMessage(
      "Messages you send after creating your link won’t be shared. Anyone with the URL can view this chat.",
    ),
    "Chat_share_markdown": MessageLookupByLibrary.simpleMessage(
      "Share as Markdown",
    ),
    "Chat_share_pdf": MessageLookupByLibrary.simpleMessage("Share as PDF"),
    "Chat_sign_in": MessageLookupByLibrary.simpleMessage("Sign In"),
    "Chat_sign_in_description": MessageLookupByLibrary.simpleMessage(
      "Sign in to access chat, or use the composite calculators without signing in.",
    ),
    "Chat_sign_in_to_chat": MessageLookupByLibrary.simpleMessage(
      "Sign In to Chat",
    ),
    "Chat_start_new_chat_help": MessageLookupByLibrary.simpleMessage(
      "Start a new chat to begin a conversation.",
    ),
    "Chat_start_voice_input": MessageLookupByLibrary.simpleMessage(
      "Start voice input",
    ),
    "Chat_starter_empty": MessageLookupByLibrary.simpleMessage(
      "Write your question below to begin.",
    ),
    "Chat_starter_hide_preview": MessageLookupByLibrary.simpleMessage(
      "Hide question",
    ),
    "Chat_starter_preview": MessageLookupByLibrary.simpleMessage(
      "Preview question",
    ),
    "Chat_starter_review_hint": MessageLookupByLibrary.simpleMessage(
      "Choose a starting point, then review your draft before sending.",
    ),
    "Chat_starter_use_question": MessageLookupByLibrary.simpleMessage(
      "Use this question",
    ),
    "Chat_starters_less": MessageLookupByLibrary.simpleMessage("Show fewer"),
    "Chat_starters_more": MessageLookupByLibrary.simpleMessage(
      "See more starting points",
    ),
    "Chat_stop_generating": MessageLookupByLibrary.simpleMessage(
      "Stop generating",
    ),
    "Chat_stop_voice_input": MessageLookupByLibrary.simpleMessage(
      "Stop voice input",
    ),
    "Chat_suggested_questions": MessageLookupByLibrary.simpleMessage(
      "Suggested questions",
    ),
    "Chat_task_calculators": MessageLookupByLibrary.simpleMessage(
      "Choose a calculator",
    ),
    "Chat_task_failure": MessageLookupByLibrary.simpleMessage(
      "Understand failure",
    ),
    "Chat_task_generic": MessageLookupByLibrary.simpleMessage(
      "Explore a question",
    ),
    "Chat_task_laminate": MessageLookupByLibrary.simpleMessage(
      "Plan a laminate",
    ),
    "Chat_task_materials": MessageLookupByLibrary.simpleMessage(
      "Compare materials",
    ),
    "Chat_task_stiffness": MessageLookupByLibrary.simpleMessage(
      "Estimate stiffness",
    ),
    "Chat_title": MessageLookupByLibrary.simpleMessage("Chat"),
    "Chat_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "Chat_unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
    "Chat_untitled_chat": MessageLookupByLibrary.simpleMessage("Untitled chat"),
    "Chat_use_as_draft": MessageLookupByLibrary.simpleMessage("Use as draft"),
    "Chat_voice_unavailable": MessageLookupByLibrary.simpleMessage(
      "Voice input is unavailable. Please check microphone permissions.",
    ),
    "Chat_welcome": MessageLookupByLibrary.simpleMessage("Welcome"),
    "Chat_welcome_description": MessageLookupByLibrary.simpleMessage(
      "Ask about materials, laminate design, failure analysis, manufacturing, or engineering calculations.",
    ),
    "Chat_welcome_name": m28,
    "Chat_working_on": MessageLookupByLibrary.simpleMessage(
      "What are you working on?",
    ),
    "Compliance_Matrix_S": MessageLookupByLibrary.simpleMessage(
      "Compliance Matrix S",
    ),
    "Composite_Material": MessageLookupByLibrary.simpleMessage(
      "Composite Material",
    ),
    "Constitutive_relation_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage(
          "Constitutive relation of linear elastic material",
        ),
    "CountdownDays": MessageLookupByLibrary.simpleMessage("Countdown Days"),
    "Deflection": MessageLookupByLibrary.simpleMessage("Deflection"),
    "Deflections_and_slopes_of_cantilever_beams":
        MessageLookupByLibrary.simpleMessage(
          "Deflections and slopes of cantilever beams",
        ),
    "Deflections_and_slopes_of_simple_beams":
        MessageLookupByLibrary.simpleMessage(
          "Deflections and slopes of simple beams",
        ),
    "Description": MessageLookupByLibrary.simpleMessage("Description"),
    "Displacement": MessageLookupByLibrary.simpleMessage("Displacement"),
    "Engineering_Constants": MessageLookupByLibrary.simpleMessage(
      "Engineering Constants",
    ),
    "Favorites": MessageLookupByLibrary.simpleMessage("Favorites"),
    "Feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "FinanceGo": MessageLookupByLibrary.simpleMessage("Finance Go"),
    "Flexure_formula_of_beam": MessageLookupByLibrary.simpleMessage(
      "Flexure formula of beam",
    ),
    "Force": MessageLookupByLibrary.simpleMessage("Force"),
    "Force_displacement_relation_of_bar": MessageLookupByLibrary.simpleMessage(
      "Force-displacement relation of bar",
    ),
    "General_stress_calculation": MessageLookupByLibrary.simpleMessage(
      "General stress calculation",
    ),
    "Inputs": MessageLookupByLibrary.simpleMessage("Inputs"),
    "Isotropic_material": MessageLookupByLibrary.simpleMessage(
      "Isotropic material",
    ),
    "Lamina_Constants": MessageLookupByLibrary.simpleMessage(
      "Lamina Constants",
    ),
    "Lamina_engineering_constants": MessageLookupByLibrary.simpleMessage(
      "Lamina Engineering Constants",
    ),
    "Lamina_stressstrain": MessageLookupByLibrary.simpleMessage(
      "Lamina Stress/Strain",
    ),
    "Laminar_stressstrain": MessageLookupByLibrary.simpleMessage(
      "Laminar Stress/Strain",
    ),
    "Laminate_3D_properties": MessageLookupByLibrary.simpleMessage(
      "Laminate 3D Properties",
    ),
    "Laminate_plate_properties": MessageLookupByLibrary.simpleMessage(
      "Laminate Plate Properties",
    ),
    "Layer_Thickness": MessageLookupByLibrary.simpleMessage("Layer Thickness"),
    "Layup_Angle": MessageLookupByLibrary.simpleMessage("Layup Angle"),
    "Layup_Sequence": MessageLookupByLibrary.simpleMessage("Layup Sequence"),
    "Legacy_data_export": MessageLookupByLibrary.simpleMessage(
      "Export legacy data",
    ),
    "Legacy_data_failed": MessageLookupByLibrary.simpleMessage(
      "Could not export legacy data. Your original data has not been changed.",
    ),
    "Legacy_data_help": MessageLookupByLibrary.simpleMessage(
      "Export a complete backup of materials and layups saved in the older Mac app. The original values and units are preserved; this backup is separate from the new material library.",
    ),
    "Legacy_data_saved": MessageLookupByLibrary.simpleMessage(
      "Legacy SwiftComp data exported.",
    ),
    "Legacy_data_title": MessageLookupByLibrary.simpleMessage(
      "Legacy SwiftComp data",
    ),
    "ME_Toolkit": MessageLookupByLibrary.simpleMessage("ME Toolkit"),
    "Mechanics_of_Material": MessageLookupByLibrary.simpleMessage(
      "Mechanics of Material",
    ),
    "Moments_of_Inertia": MessageLookupByLibrary.simpleMessage(
      "Moments of Inertia",
    ),
    "Moments_of_inertia_of_plane_areas": MessageLookupByLibrary.simpleMessage(
      "Moments of inertia of plane areas",
    ),
    "MoneyTracker": MessageLookupByLibrary.simpleMessage("Money Tracker"),
    "Monoclinic_material": MessageLookupByLibrary.simpleMessage(
      "Monoclinic material",
    ),
    "More": MessageLookupByLibrary.simpleMessage("More"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("More Apps"),
    "MyFavourite": MessageLookupByLibrary.simpleMessage("My Favourite"),
    "NASALover": MessageLookupByLibrary.simpleMessage("NASA Lover"),
    "Not_a_number": MessageLookupByLibrary.simpleMessage("Not a number"),
    "NovelsHub": MessageLookupByLibrary.simpleMessage("Novels Hub"),
    "Orthotropic_material": MessageLookupByLibrary.simpleMessage(
      "Orthotropic material",
    ),
    "Plane_Stresses": MessageLookupByLibrary.simpleMessage("Plane Stresses"),
    "Plane_stresses_transformation": MessageLookupByLibrary.simpleMessage(
      "Plane stresses transformation",
    ),
    "Principal_stresses_and_plane": MessageLookupByLibrary.simpleMessage(
      "Principal stresses and plane",
    ),
    "RatethisApp": MessageLookupByLibrary.simpleMessage("Rate this App"),
    "Result": MessageLookupByLibrary.simpleMessage("Result"),
    "Result_Precision": MessageLookupByLibrary.simpleMessage(
      "Result Precision",
    ),
    "Result_Strain": MessageLookupByLibrary.simpleMessage("Result Strain"),
    "Result_Stress": MessageLookupByLibrary.simpleMessage("Result Stress"),
    "Results": MessageLookupByLibrary.simpleMessage("Results"),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "SharethisApp": MessageLookupByLibrary.simpleMessage("Share this App"),
    "Slope": MessageLookupByLibrary.simpleMessage("Slope"),
    "Stiffness_Matrix_C": MessageLookupByLibrary.simpleMessage(
      "Stiffness Matrix C",
    ),
    "Stiffness_Matrix_Q": MessageLookupByLibrary.simpleMessage(
      "Stiffness Matrix Q",
    ),
    "Strain": MessageLookupByLibrary.simpleMessage("Strain"),
    "Stress": MessageLookupByLibrary.simpleMessage("Stress"),
    "Stresses_in_a_thin_walled_cylindrical_pressure_vessel":
        MessageLookupByLibrary.simpleMessage(
          "Stresses in a thin-walled cylindrical pressure vessel",
        ),
    "Stresses_in_the_wall_of_a_spherical_shell":
        MessageLookupByLibrary.simpleMessage(
          "Stresses in the wall of a spherical shell",
        ),
    "Stressstrain_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage(
          "Stress/strain of linear elastic material",
        ),
    "The_Maximum_Shear_Stress": MessageLookupByLibrary.simpleMessage(
      "The Maximum Shear Stress",
    ),
    "Theory_of_Elasticity": MessageLookupByLibrary.simpleMessage(
      "Theory of Elasticity",
    ),
    "Torsion_formula_of_bar": MessageLookupByLibrary.simpleMessage(
      "Torsion formula of bar",
    ),
    "Transversely_isotropic_material": MessageLookupByLibrary.simpleMessage(
      "Transversely isotropic material",
    ),
    "UDFRC_Properties": MessageLookupByLibrary.simpleMessage(
      "UDFRC Properties",
    ),
  };
}
