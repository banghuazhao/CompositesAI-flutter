// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m0(value, unit) => "深度：${value} ${unit}";

  static String m1(ply, surface) => "第 ${ply} 层 · ${surface}";

  static String m2(name) => "“${name}”将从材料库中移除。";

  static String m3(name) => "删除 ${name}";

  static String m4(angles) => "铺层角度：${angles}";

  static String m5(shown, total) => "已显示 ${shown} / ${total} 个表面。导出包括所有表面。";

  static String m6(ply, surface) => "选中的表面：第 ${ply} 层，${surface}";

  static String m7(units) => "数值将以 ${units} 填入。典型公开数据仅供初步设计参考，请核对供应商数据表。";

  static String m8(kind) => "${kind}材料库";

  static String m9(name) => "已将“${name}”保存到材料库。";

  static String m10(unit) => "数值对于 ${unit} 过大，请检查单位";

  static String m11(count) => "另有 ${count} 层";

  static String m12(count) => "${count} 层";

  static String m13(name) => "已存在名为“${name}”的材料。您可以替换其已保存的数据，或选择其他名称。";

  static String m14(value, unit) => "总厚度：${value} ${unit}";

  static String m15(modulus, stress, length, loads) =>
      "模量 ${modulus} · 应力 ${stress} · 长度 ${length} · 载荷 ${loads}";

  static String m16(question) => "提问：${question}";

  static String m17(count) => "${count} 个附件";

  static String m18(language) => "${language} - 生成中";

  static String m19(name) => "删除“${name}”？此操作无法撤销。";

  static String m20(count) => "${count} 个文件";

  static String m21(dateTime) => "消息时间：${dateTime}";

  static String m22(name) => "预览 ${name}";

  static String m23(error) => "处理失败：${error}";

  static String m24(name) => "阅读 ${name}";

  static String m25(name) => "移除 ${name}";

  static String m26(query) => "搜索“${query}”";

  static String m27(count) => "${count} 条匹配的消息";

  static String m28(name) => "欢迎，${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage("旋转角度"),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage("各向异性材料"),
    "Area": MessageLookupByLibrary.simpleMessage("面积"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("屈曲载荷"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage("杆的屈曲载荷计算"),
    "Calculate": MessageLookupByLibrary.simpleMessage("计算"),
    "Calculator_all_failure_criteria": MessageLookupByLibrary.simpleMessage(
      "所有准则",
    ),
    "Calculator_apply_material": MessageLookupByLibrary.simpleMessage("应用材料"),
    "Calculator_built_in_materials": MessageLookupByLibrary.simpleMessage(
      "内置材料",
    ),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "无法计算结果，请检查材料常数、载荷和厚度。",
    ),
    "Calculator_chart_depth": m0,
    "Calculator_chart_inspection_hint": MessageLookupByLibrary.simpleMessage(
      "点击或悬停数据点以查看各层数值",
    ),
    "Calculator_chart_ply_surface": m1,
    "Calculator_choose_another_name": MessageLookupByLibrary.simpleMessage(
      "选择其他名称",
    ),
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage("清除铺层次序"),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "无法复制结果，请重试。",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage("复制结果"),
    "Calculator_delete_material_message": m2,
    "Calculator_delete_material_title": MessageLookupByLibrary.simpleMessage(
      "删除材料？",
    ),
    "Calculator_delete_material_tooltip": m3,
    "Calculator_expanded_angles": m4,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage("无法导出结果。"),
    "Calculator_export_materials": MessageLookupByLibrary.simpleMessage(
      "导出我的材料（JSON）",
    ),
    "Calculator_export_materials_help": MessageLookupByLibrary.simpleMessage(
      "导出所有已保存的材料，数值使用 SI 单位，包括当前搜索结果以外的材料。",
    ),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage("导出结果"),
    "Calculator_failed_surfaces_only": MessageLookupByLibrary.simpleMessage(
      "仅显示失效表面",
    ),
    "Calculator_failure_criterion": MessageLookupByLibrary.simpleMessage("准则"),
    "Calculator_failure_exports_all": MessageLookupByLibrary.simpleMessage(
      "导出始终包含所有表面和失效准则。",
    ),
    "Calculator_failure_filter_summary": m5,
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "请输入有限数值",
    ),
    "Calculator_focused_surface": m6,
    "Calculator_library": MessageLookupByLibrary.simpleMessage("材料库"),
    "Calculator_material_alphabetical_order":
        MessageLookupByLibrary.simpleMessage("名称（A–Z）"),
    "Calculator_material_delete_failed": MessageLookupByLibrary.simpleMessage(
      "无法删除此材料，请重试。",
    ),
    "Calculator_material_details": MessageLookupByLibrary.simpleMessage("材料详情"),
    "Calculator_material_elastic_properties":
        MessageLookupByLibrary.simpleMessage("弹性性能"),
    "Calculator_material_elastic_required":
        MessageLookupByLibrary.simpleMessage("请先输入弹性常数，再保存材料。"),
    "Calculator_material_export_empty": MessageLookupByLibrary.simpleMessage(
      "保存自定义材料后即可导出 JSON。",
    ),
    "Calculator_material_export_failed": MessageLookupByLibrary.simpleMessage(
      "无法导出已保存的材料，请重试。",
    ),
    "Calculator_material_kind_fiber": MessageLookupByLibrary.simpleMessage(
      "纤维",
    ),
    "Calculator_material_kind_lamina": MessageLookupByLibrary.simpleMessage(
      "单向复合材料层",
    ),
    "Calculator_material_kind_matrix": MessageLookupByLibrary.simpleMessage(
      "基体",
    ),
    "Calculator_material_library_help": m7,
    "Calculator_material_library_title": m8,
    "Calculator_material_missing_note": MessageLookupByLibrary.simpleMessage(
      "未提供的弹性数值将保留当前输入。未提供的热膨胀或强度数据组也将保留当前输入。",
    ),
    "Calculator_material_name": MessageLookupByLibrary.simpleMessage("材料名称"),
    "Calculator_material_not_provided": MessageLookupByLibrary.simpleMessage(
      "未提供",
    ),
    "Calculator_material_order": MessageLookupByLibrary.simpleMessage("排序"),
    "Calculator_material_original_order": MessageLookupByLibrary.simpleMessage(
      "原始顺序",
    ),
    "Calculator_material_save_failed": MessageLookupByLibrary.simpleMessage(
      "无法保存此材料，请检查数值后重试。",
    ),
    "Calculator_material_saved": m9,
    "Calculator_material_source": MessageLookupByLibrary.simpleMessage("来源"),
    "Calculator_material_strengths": MessageLookupByLibrary.simpleMessage("强度"),
    "Calculator_material_strengths_note": MessageLookupByLibrary.simpleMessage(
      "仅当五项强度值均已提供时，才会一起应用这些强度值。",
    ),
    "Calculator_material_thermal_note": MessageLookupByLibrary.simpleMessage(
      "应用热膨胀系数需要提供 α11（各向同性材料为 α）。对于复合材料层和纤维，未提供的 α22 使用 α11，剪切热膨胀系数设为零。",
    ),
    "Calculator_material_thermal_properties":
        MessageLookupByLibrary.simpleMessage("热膨胀系数"),
    "Calculator_material_type": MessageLookupByLibrary.simpleMessage("材料类型"),
    "Calculator_modulus_too_large": m10,
    "Calculator_more_plies": m11,
    "Calculator_my_materials": MessageLookupByLibrary.simpleMessage("我的材料"),
    "Calculator_no_failed_surfaces": MessageLookupByLibrary.simpleMessage(
      "没有符合此准则的失效表面。",
    ),
    "Calculator_no_failure_results": MessageLookupByLibrary.simpleMessage(
      "暂无失效分析结果。",
    ),
    "Calculator_no_material_matches": MessageLookupByLibrary.simpleMessage(
      "没有符合搜索条件的材料。",
    ),
    "Calculator_ply_count": m12,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "必须介于 -1 和 0.5 之间",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage("必须大于零"),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "厚度必须大于零",
    ),
    "Calculator_replace_material": MessageLookupByLibrary.simpleMessage("替换"),
    "Calculator_replace_material_message": m13,
    "Calculator_replace_material_title": MessageLookupByLibrary.simpleMessage(
      "替换已保存的材料？",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "结果已复制到剪贴板",
    ),
    "Calculator_save_current_material": MessageLookupByLibrary.simpleMessage(
      "将当前输入保存为材料",
    ),
    "Calculator_save_material_title": MessageLookupByLibrary.simpleMessage(
      "保存材料",
    ),
    "Calculator_search_materials": MessageLookupByLibrary.simpleMessage("搜索材料"),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage("分享 CSV 文件"),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage("分享 PDF 文件"),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("国际单位制（SI）"),
    "Calculator_surface_bottom": MessageLookupByLibrary.simpleMessage("底面"),
    "Calculator_surface_top": MessageLookupByLibrary.simpleMessage("顶面"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("厚度"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "铺层数量过多",
    ),
    "Calculator_total_thickness": m14,
    "Calculator_unit_details": m15,
    "Calculator_units": MessageLookupByLibrary.simpleMessage("计算器单位"),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "输入、结果和导出文件均使用这些单位。已输入的数值不会自动换算。",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("美制单位"),
    "Calculator_view_in_table": MessageLookupByLibrary.simpleMessage("在表格中查看"),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "必须介于 0 和 1 之间",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage("铺层次序无效"),
    "Chat_account_settings": MessageLookupByLibrary.simpleMessage("账户与设置"),
    "Chat_add_attachment": MessageLookupByLibrary.simpleMessage("添加附件"),
    "Chat_archive": MessageLookupByLibrary.simpleMessage("归档"),
    "Chat_archived": MessageLookupByLibrary.simpleMessage("已归档"),
    "Chat_ask_question": m16,
    "Chat_attach_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "添加 RAG 来源",
    ),
    "Chat_attachment_count": m17,
    "Chat_bad_response": MessageLookupByLibrary.simpleMessage("不好的回复"),
    "Chat_camera": MessageLookupByLibrary.simpleMessage("相机"),
    "Chat_cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Chat_chat_options": MessageLookupByLibrary.simpleMessage("聊天选项"),
    "Chat_chat_title": MessageLookupByLibrary.simpleMessage("标题"),
    "Chat_chats": MessageLookupByLibrary.simpleMessage("聊天"),
    "Chat_clear": MessageLookupByLibrary.simpleMessage("清除"),
    "Chat_clear_draft": MessageLookupByLibrary.simpleMessage("清空草稿"),
    "Chat_clear_search": MessageLookupByLibrary.simpleMessage("清除搜索"),
    "Chat_close_image_preview": MessageLookupByLibrary.simpleMessage("关闭图片预览"),
    "Chat_code": MessageLookupByLibrary.simpleMessage("代码"),
    "Chat_code_copy_failed": MessageLookupByLibrary.simpleMessage("无法复制此代码。"),
    "Chat_code_streaming": m18,
    "Chat_collapse_answer": MessageLookupByLibrary.simpleMessage("收起回答"),
    "Chat_composer_done": MessageLookupByLibrary.simpleMessage("完成"),
    "Chat_composer_hint": MessageLookupByLibrary.simpleMessage("询问复合材料工程问题…"),
    "Chat_composite_calculators": MessageLookupByLibrary.simpleMessage(
      "复合材料计算器",
    ),
    "Chat_composite_expert": MessageLookupByLibrary.simpleMessage("复合材料专家"),
    "Chat_copied": MessageLookupByLibrary.simpleMessage("已复制"),
    "Chat_copy_code": MessageLookupByLibrary.simpleMessage("复制代码"),
    "Chat_copy_exchange": MessageLookupByLibrary.simpleMessage("复制问题和回答"),
    "Chat_copy_link": MessageLookupByLibrary.simpleMessage("复制链接"),
    "Chat_copy_message": MessageLookupByLibrary.simpleMessage("复制消息"),
    "Chat_delete": MessageLookupByLibrary.simpleMessage("删除"),
    "Chat_delete_chat_message": m19,
    "Chat_delete_chat_title": MessageLookupByLibrary.simpleMessage("删除聊天？"),
    "Chat_delete_untitled_chat_message": MessageLookupByLibrary.simpleMessage(
      "删除此聊天？此操作无法撤销。",
    ),
    "Chat_draft": MessageLookupByLibrary.simpleMessage("草稿"),
    "Chat_draft_cleared": MessageLookupByLibrary.simpleMessage("已清空草稿。"),
    "Chat_edit_negative_feedback": MessageLookupByLibrary.simpleMessage(
      "编辑负面反馈",
    ),
    "Chat_edit_positive_feedback": MessageLookupByLibrary.simpleMessage(
      "编辑正面反馈",
    ),
    "Chat_engineering_copilot": MessageLookupByLibrary.simpleMessage(
      "复合材料工程助手",
    ),
    "Chat_exchange_answer": MessageLookupByLibrary.simpleMessage("回答"),
    "Chat_exchange_copied": MessageLookupByLibrary.simpleMessage("已复制问题和回答"),
    "Chat_exchange_copy_failed": MessageLookupByLibrary.simpleMessage(
      "无法复制这组问答。",
    ),
    "Chat_exchange_question": MessageLookupByLibrary.simpleMessage("问题"),
    "Chat_expand_answer": MessageLookupByLibrary.simpleMessage("展开回答"),
    "Chat_expand_composer": MessageLookupByLibrary.simpleMessage("展开输入框"),
    "Chat_expanded_composer": MessageLookupByLibrary.simpleMessage("编辑问题"),
    "Chat_export_conversation": MessageLookupByLibrary.simpleMessage("导出对话"),
    "Chat_export_failed": MessageLookupByLibrary.simpleMessage("无法导出此对话。"),
    "Chat_feedback_accurate": MessageLookupByLibrary.simpleMessage("准确"),
    "Chat_feedback_additional_details": MessageLookupByLibrary.simpleMessage(
      "补充说明",
    ),
    "Chat_feedback_clear_explanation": MessageLookupByLibrary.simpleMessage(
      "解释清晰",
    ),
    "Chat_feedback_did_not_follow": MessageLookupByLibrary.simpleMessage(
      "未遵循指示",
    ),
    "Chat_feedback_excellent": MessageLookupByLibrary.simpleMessage("10 · 优秀"),
    "Chat_feedback_followed_instructions": MessageLookupByLibrary.simpleMessage(
      "遵循了指示",
    ),
    "Chat_feedback_good_structure": MessageLookupByLibrary.simpleMessage(
      "结构良好",
    ),
    "Chat_feedback_help": MessageLookupByLibrary.simpleMessage(
      "您的反馈有助于改善回答质量。",
    ),
    "Chat_feedback_helpful": MessageLookupByLibrary.simpleMessage("有帮助"),
    "Chat_feedback_inaccurate": MessageLookupByLibrary.simpleMessage("不准确"),
    "Chat_feedback_needs_work": MessageLookupByLibrary.simpleMessage("需要改进"),
    "Chat_feedback_not_useful": MessageLookupByLibrary.simpleMessage("没有帮助"),
    "Chat_feedback_optional": MessageLookupByLibrary.simpleMessage("选填"),
    "Chat_feedback_other": MessageLookupByLibrary.simpleMessage("其他"),
    "Chat_feedback_poor": MessageLookupByLibrary.simpleMessage("1 · 差"),
    "Chat_feedback_quality_score": MessageLookupByLibrary.simpleMessage("质量评分"),
    "Chat_feedback_reason_prompt": MessageLookupByLibrary.simpleMessage(
      "哪些因素影响了您的评分？",
    ),
    "Chat_feedback_reason_required": MessageLookupByLibrary.simpleMessage(
      "请至少选择一个原因以继续。",
    ),
    "Chat_feedback_save_failed": MessageLookupByLibrary.simpleMessage(
      "无法保存反馈。请重试。",
    ),
    "Chat_feedback_saved": MessageLookupByLibrary.simpleMessage("反馈已保存。"),
    "Chat_feedback_submit": MessageLookupByLibrary.simpleMessage("提交反馈"),
    "Chat_feedback_submitted": MessageLookupByLibrary.simpleMessage("反馈已提交"),
    "Chat_feedback_title": MessageLookupByLibrary.simpleMessage("评价此回复"),
    "Chat_feedback_too_verbose": MessageLookupByLibrary.simpleMessage("过于冗长"),
    "Chat_feedback_unclear": MessageLookupByLibrary.simpleMessage("不清晰"),
    "Chat_feedback_update": MessageLookupByLibrary.simpleMessage("更新反馈"),
    "Chat_feedback_useful_detail": MessageLookupByLibrary.simpleMessage("细节有用"),
    "Chat_file_count": m20,
    "Chat_files": MessageLookupByLibrary.simpleMessage("文件"),
    "Chat_find_in_chat": MessageLookupByLibrary.simpleMessage("在聊天中查找"),
    "Chat_folder_name": MessageLookupByLibrary.simpleMessage("文件夹名称"),
    "Chat_generating_response_stop": MessageLookupByLibrary.simpleMessage(
      "正在生成回复。停止生成",
    ),
    "Chat_get_response": MessageLookupByLibrary.simpleMessage("获取回复"),
    "Chat_good_response": MessageLookupByLibrary.simpleMessage("好的回复"),
    "Chat_image_preview": MessageLookupByLibrary.simpleMessage("图片预览"),
    "Chat_image_preview_unavailable": MessageLookupByLibrary.simpleMessage(
      "无法预览此图片。",
    ),
    "Chat_jump_to_latest": MessageLookupByLibrary.simpleMessage("跳至最新消息"),
    "Chat_knowledge": MessageLookupByLibrary.simpleMessage("知识库"),
    "Chat_knowledge_collection": MessageLookupByLibrary.simpleMessage("知识集合"),
    "Chat_knowledge_file": MessageLookupByLibrary.simpleMessage("知识文件"),
    "Chat_link_copied": MessageLookupByLibrary.simpleMessage("链接已复制到剪贴板"),
    "Chat_message_time": m21,
    "Chat_models": MessageLookupByLibrary.simpleMessage("模型"),
    "Chat_more": MessageLookupByLibrary.simpleMessage("更多"),
    "Chat_more_actions": MessageLookupByLibrary.simpleMessage("更多操作"),
    "Chat_move_to_folder": MessageLookupByLibrary.simpleMessage("移至文件夹"),
    "Chat_new_chat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "Chat_new_folder": MessageLookupByLibrary.simpleMessage("新建文件夹"),
    "Chat_no_chats": MessageLookupByLibrary.simpleMessage("暂无聊天"),
    "Chat_no_chats_found": MessageLookupByLibrary.simpleMessage("未找到聊天"),
    "Chat_no_folder_chats": MessageLookupByLibrary.simpleMessage("文件夹中暂无聊天"),
    "Chat_no_folders": MessageLookupByLibrary.simpleMessage("暂无文件夹"),
    "Chat_no_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "未找到知识来源",
    ),
    "Chat_no_matching_chats": MessageLookupByLibrary.simpleMessage("没有匹配的聊天"),
    "Chat_open_calculators": MessageLookupByLibrary.simpleMessage("打开复合材料计算器"),
    "Chat_open_link_failed": MessageLookupByLibrary.simpleMessage("无法打开此链接。"),
    "Chat_photo_library": MessageLookupByLibrary.simpleMessage("照片图库"),
    "Chat_pin": MessageLookupByLibrary.simpleMessage("置顶"),
    "Chat_pinned": MessageLookupByLibrary.simpleMessage("已置顶"),
    "Chat_preview_image": m22,
    "Chat_processing_document": MessageLookupByLibrary.simpleMessage("正在处理文档…"),
    "Chat_processing_failed": MessageLookupByLibrary.simpleMessage("处理失败"),
    "Chat_processing_failed_detail": m23,
    "Chat_read_file": m24,
    "Chat_refresh_knowledge": MessageLookupByLibrary.simpleMessage("刷新知识库"),
    "Chat_regenerate_response": MessageLookupByLibrary.simpleMessage("重新生成回复"),
    "Chat_remove_attachment": m25,
    "Chat_remove_from_folder": MessageLookupByLibrary.simpleMessage("从文件夹移除"),
    "Chat_rename": MessageLookupByLibrary.simpleMessage("重命名"),
    "Chat_rename_chat": MessageLookupByLibrary.simpleMessage("重命名聊天"),
    "Chat_replace_draft": MessageLookupByLibrary.simpleMessage("替换草稿"),
    "Chat_replace_draft_message": MessageLookupByLibrary.simpleMessage(
      "用此消息替换当前尚未发送的文字？",
    ),
    "Chat_replace_draft_title": MessageLookupByLibrary.simpleMessage("替换草稿？"),
    "Chat_response_interrupted": MessageLookupByLibrary.simpleMessage("回复已中断"),
    "Chat_save": MessageLookupByLibrary.simpleMessage("保存"),
    "Chat_search_all": MessageLookupByLibrary.simpleMessage("全部"),
    "Chat_search_answers": MessageLookupByLibrary.simpleMessage("回答"),
    "Chat_search_assistant": MessageLookupByLibrary.simpleMessage("助手"),
    "Chat_search_chats": MessageLookupByLibrary.simpleMessage("搜索聊天"),
    "Chat_search_clear": MessageLookupByLibrary.simpleMessage("清除搜索"),
    "Chat_search_copy_excerpt": MessageLookupByLibrary.simpleMessage("复制摘录"),
    "Chat_search_copy_failed": MessageLookupByLibrary.simpleMessage("无法复制此摘录。"),
    "Chat_search_empty": MessageLookupByLibrary.simpleMessage("输入文字以搜索此对话。"),
    "Chat_search_excerpt_copied": MessageLookupByLibrary.simpleMessage("摘录已复制"),
    "Chat_search_history_title": m26,
    "Chat_search_knowledge": MessageLookupByLibrary.simpleMessage("搜索知识库"),
    "Chat_search_loaded_messages": MessageLookupByLibrary.simpleMessage(
      "搜索已加载的消息",
    ),
    "Chat_search_match_count": m27,
    "Chat_search_no_matches": MessageLookupByLibrary.simpleMessage("没有匹配的消息。"),
    "Chat_search_questions": MessageLookupByLibrary.simpleMessage("问题"),
    "Chat_search_you": MessageLookupByLibrary.simpleMessage("您"),
    "Chat_select_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "Chat_send_message": MessageLookupByLibrary.simpleMessage("发送消息"),
    "Chat_share": MessageLookupByLibrary.simpleMessage("分享"),
    "Chat_share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
    "Chat_share_chat_description": MessageLookupByLibrary.simpleMessage(
      "创建链接后发送的消息不会被分享。任何获得此链接的人都可以查看此聊天。",
    ),
    "Chat_share_markdown": MessageLookupByLibrary.simpleMessage("分享为 Markdown"),
    "Chat_share_pdf": MessageLookupByLibrary.simpleMessage("分享为 PDF"),
    "Chat_sign_in": MessageLookupByLibrary.simpleMessage("登录"),
    "Chat_sign_in_description": MessageLookupByLibrary.simpleMessage(
      "登录以使用聊天功能，也可免登录使用复合材料计算器。",
    ),
    "Chat_sign_in_to_chat": MessageLookupByLibrary.simpleMessage("登录以聊天"),
    "Chat_start_new_chat_help": MessageLookupByLibrary.simpleMessage(
      "新建聊天以开始对话。",
    ),
    "Chat_start_voice_input": MessageLookupByLibrary.simpleMessage("开始语音输入"),
    "Chat_starter_empty": MessageLookupByLibrary.simpleMessage("在下方输入问题即可开始。"),
    "Chat_starter_hide_preview": MessageLookupByLibrary.simpleMessage("收起问题"),
    "Chat_starter_preview": MessageLookupByLibrary.simpleMessage("预览问题"),
    "Chat_starter_review_hint": MessageLookupByLibrary.simpleMessage(
      "先选择一个起点，发送前再检查草稿。",
    ),
    "Chat_starter_use_question": MessageLookupByLibrary.simpleMessage("使用此问题"),
    "Chat_starters_less": MessageLookupByLibrary.simpleMessage("显示较少"),
    "Chat_starters_more": MessageLookupByLibrary.simpleMessage("查看更多起点"),
    "Chat_stop_generating": MessageLookupByLibrary.simpleMessage("停止生成"),
    "Chat_stop_voice_input": MessageLookupByLibrary.simpleMessage("停止语音输入"),
    "Chat_suggested_questions": MessageLookupByLibrary.simpleMessage("建议问题"),
    "Chat_task_calculators": MessageLookupByLibrary.simpleMessage("选择计算器"),
    "Chat_task_failure": MessageLookupByLibrary.simpleMessage("了解失效"),
    "Chat_task_generic": MessageLookupByLibrary.simpleMessage("探索问题"),
    "Chat_task_laminate": MessageLookupByLibrary.simpleMessage("规划铺层"),
    "Chat_task_materials": MessageLookupByLibrary.simpleMessage("比较材料"),
    "Chat_task_stiffness": MessageLookupByLibrary.simpleMessage("估算刚度"),
    "Chat_title": MessageLookupByLibrary.simpleMessage("聊天"),
    "Chat_undo": MessageLookupByLibrary.simpleMessage("撤销"),
    "Chat_unpin": MessageLookupByLibrary.simpleMessage("取消置顶"),
    "Chat_untitled_chat": MessageLookupByLibrary.simpleMessage("未命名聊天"),
    "Chat_use_as_draft": MessageLookupByLibrary.simpleMessage("用作草稿"),
    "Chat_voice_unavailable": MessageLookupByLibrary.simpleMessage(
      "语音输入不可用。请检查麦克风权限。",
    ),
    "Chat_welcome": MessageLookupByLibrary.simpleMessage("欢迎"),
    "Chat_welcome_description": MessageLookupByLibrary.simpleMessage(
      "询问有关材料、层合板设计、失效分析、制造或工程计算的问题。",
    ),
    "Chat_welcome_name": m28,
    "Chat_working_on": MessageLookupByLibrary.simpleMessage("您正在研究什么？"),
    "Compliance_Matrix_S": MessageLookupByLibrary.simpleMessage("柔度矩阵 S"),
    "Composite_Material": MessageLookupByLibrary.simpleMessage("复合材料力学"),
    "Constitutive_relation_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("线弹性材料的本构关系"),
    "CountdownDays": MessageLookupByLibrary.simpleMessage("日期倒计时"),
    "Deflection": MessageLookupByLibrary.simpleMessage("挠度"),
    "Deflections_and_slopes_of_cantilever_beams":
        MessageLookupByLibrary.simpleMessage("悬臂梁的挠度和斜率"),
    "Deflections_and_slopes_of_simple_beams":
        MessageLookupByLibrary.simpleMessage("简单梁的挠度和斜率"),
    "Description": MessageLookupByLibrary.simpleMessage("描述"),
    "Displacement": MessageLookupByLibrary.simpleMessage("位移"),
    "Engineering_Constants": MessageLookupByLibrary.simpleMessage("工程常数"),
    "Favorites": MessageLookupByLibrary.simpleMessage("收藏"),
    "Feedback": MessageLookupByLibrary.simpleMessage("反馈"),
    "FinanceGo": MessageLookupByLibrary.simpleMessage("美股财报通"),
    "Flexure_formula_of_beam": MessageLookupByLibrary.simpleMessage("梁的弯曲公式"),
    "Force": MessageLookupByLibrary.simpleMessage("力"),
    "Force_displacement_relation_of_bar": MessageLookupByLibrary.simpleMessage(
      "杆的力-位移关系",
    ),
    "General_stress_calculation": MessageLookupByLibrary.simpleMessage("应力计算"),
    "Inputs": MessageLookupByLibrary.simpleMessage("输入"),
    "Isotropic_material": MessageLookupByLibrary.simpleMessage("各向同性材料"),
    "Lamina_Constants": MessageLookupByLibrary.simpleMessage("单层板工程常数"),
    "Lamina_engineering_constants": MessageLookupByLibrary.simpleMessage(
      "单层板工程常数",
    ),
    "Lamina_stressstrain": MessageLookupByLibrary.simpleMessage("单层板应力/应变"),
    "Laminar_stressstrain": MessageLookupByLibrary.simpleMessage("层合板应力/应变"),
    "Laminate_3D_properties": MessageLookupByLibrary.simpleMessage("层合板 3D 属性"),
    "Laminate_plate_properties": MessageLookupByLibrary.simpleMessage(
      "层合板平面属性",
    ),
    "Layer_Thickness": MessageLookupByLibrary.simpleMessage("单层厚度"),
    "Layup_Angle": MessageLookupByLibrary.simpleMessage("铺层角"),
    "Layup_Sequence": MessageLookupByLibrary.simpleMessage("铺层次序"),
    "Legacy_data_export": MessageLookupByLibrary.simpleMessage("导出旧版数据"),
    "Legacy_data_failed": MessageLookupByLibrary.simpleMessage(
      "无法导出旧版数据，原始数据未被更改。",
    ),
    "Legacy_data_help": MessageLookupByLibrary.simpleMessage(
      "导出旧版 Mac 应用中保存的全部材料和铺层数据。备份保留原始数值和单位，与新版材料库分开保存。",
    ),
    "Legacy_data_saved": MessageLookupByLibrary.simpleMessage(
      "已导出旧版 SwiftComp 数据。",
    ),
    "Legacy_data_title": MessageLookupByLibrary.simpleMessage(
      "旧版 SwiftComp 数据",
    ),
    "ME_Toolkit": MessageLookupByLibrary.simpleMessage("工程工具箱"),
    "Mechanics_of_Material": MessageLookupByLibrary.simpleMessage("材料力学"),
    "Moments_of_Inertia": MessageLookupByLibrary.simpleMessage("惯性矩"),
    "Moments_of_inertia_of_plane_areas": MessageLookupByLibrary.simpleMessage(
      "平面区域的惯性矩",
    ),
    "MoneyTracker": MessageLookupByLibrary.simpleMessage("极简记账"),
    "Monoclinic_material": MessageLookupByLibrary.simpleMessage("单斜材料"),
    "More": MessageLookupByLibrary.simpleMessage("更多"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("更多应用"),
    "MyFavourite": MessageLookupByLibrary.simpleMessage("我的收藏"),
    "NASALover": MessageLookupByLibrary.simpleMessage("NASA迷"),
    "Not_a_number": MessageLookupByLibrary.simpleMessage("非数值"),
    "NovelsHub": MessageLookupByLibrary.simpleMessage("英文小说站"),
    "Orthotropic_material": MessageLookupByLibrary.simpleMessage("正交各向异性材料"),
    "Plane_Stresses": MessageLookupByLibrary.simpleMessage("平面应力"),
    "Plane_stresses_transformation": MessageLookupByLibrary.simpleMessage(
      "平面应力变换",
    ),
    "Principal_stresses_and_plane": MessageLookupByLibrary.simpleMessage(
      "主应力和平面",
    ),
    "RatethisApp": MessageLookupByLibrary.simpleMessage("给应用评分"),
    "Result": MessageLookupByLibrary.simpleMessage("结果"),
    "Result_Precision": MessageLookupByLibrary.simpleMessage("结果精度"),
    "Result_Strain": MessageLookupByLibrary.simpleMessage("应变结果"),
    "Result_Stress": MessageLookupByLibrary.simpleMessage("应力结果"),
    "Results": MessageLookupByLibrary.simpleMessage("结果"),
    "Settings": MessageLookupByLibrary.simpleMessage("设置"),
    "SharethisApp": MessageLookupByLibrary.simpleMessage("分享应用"),
    "Slope": MessageLookupByLibrary.simpleMessage("斜率"),
    "Stiffness_Matrix_C": MessageLookupByLibrary.simpleMessage("刚度矩阵 C"),
    "Stiffness_Matrix_Q": MessageLookupByLibrary.simpleMessage("刚度矩阵 Q"),
    "Strain": MessageLookupByLibrary.simpleMessage("应变"),
    "Stress": MessageLookupByLibrary.simpleMessage("应力"),
    "Stresses_in_a_thin_walled_cylindrical_pressure_vessel":
        MessageLookupByLibrary.simpleMessage("薄壁圆柱形压力容器中的应力"),
    "Stresses_in_the_wall_of_a_spherical_shell":
        MessageLookupByLibrary.simpleMessage("球壳壁中的应力"),
    "Stressstrain_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("线弹性材料的应力/应变"),
    "The_Maximum_Shear_Stress": MessageLookupByLibrary.simpleMessage("最大切应力"),
    "Theory_of_Elasticity": MessageLookupByLibrary.simpleMessage("弹性力学"),
    "Torsion_formula_of_bar": MessageLookupByLibrary.simpleMessage("杆的扭力公式"),
    "Transversely_isotropic_material": MessageLookupByLibrary.simpleMessage(
      "横向各向同性材料",
    ),
    "UDFRC_Properties": MessageLookupByLibrary.simpleMessage("单向纤维复合材料属性"),
  };
}
