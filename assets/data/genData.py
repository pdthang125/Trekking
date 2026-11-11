#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_dataset.py - Tạo dataset cho bài toán: triệu chứng -> tình huống -> sơ cứu (dã ngoại)

Luồng chạy (mỗi bước là một lệnh con):

  1) init        Tạo data/conditions.json (danh mục nhãn + dấu hiệu "seed" + triage)
  2) utterances  Sinh câu mô tả triệu chứng theo hướng NHÃN -> TRIỆU CHỨNG
                 (persona, bối cảnh, nhiễu chính tả; backend llm hoặc template)
  3) filter      Phân loại "mù" để phát hiện câu sai nhãn / quá mơ hồ
  4) split       Khử trùng lặp, chia train/val/test (có thể giữ riêng 1 persona làm test)
  5) first-aid   Sinh bản nháp sơ cứu TỪ NGUỒN bạn cung cấp + kiểm tra chéo (cần LLM)
  6) validate    Kiểm tra tính nhất quán giữa các file

Ví dụ:
  python generate_dataset.py init
  python generate_dataset.py utterances --backend template --per-label 80      # chạy thử, không cần API
  export ANTHROPIC_API_KEY=...                                                  # dùng LLM thật
  python generate_dataset.py utterances --backend llm --per-label 300
  python generate_dataset.py filter --method llm --judge-model claude-haiku-5-5
  python generate_dataset.py split --holdout-persona huong_dan_vien
  python generate_dataset.py first-aid          # cần data/sources/<condition_id>.txt
  python generate_dataset.py validate

Cảnh báo: dữ liệu "signs" trong conditions.json là bản SEED do người soạn script viết,
cần đối chiếu với nguồn chính thống (IFRC / ERC / WMS) trước khi dùng cho báo cáo.
Nội dung sơ cứu sinh ra chỉ là BẢN NHÁP, phải được người rà soát. Dự án học tập, không dùng cho người thật.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import random
import re
import sys
import time
import unicodedata
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DEFAULT_MODEL = os.environ.get("GEN_MODEL", "claude-sonnet-5-5")
DEFAULT_JUDGE = os.environ.get("JUDGE_MODEL", "claude-haiku-5-5")  # nên khác model sinh

# ---------------------------------------------------------------------------
# 1. Dữ liệu seed: persona, bối cảnh, danh mục tình huống
# ---------------------------------------------------------------------------

PERSONAS = [
    {"id": "phuot_ca_nhan", "noise": 0.3,
     "desc": "người đi phượt tự mô tả tình trạng của chính mình, văn nói tự nhiên",
     "subjects": ["Tôi", "Mình", "Tui"]},
    {"id": "truong_nhom", "noise": 0.3,
     "desc": "trưởng nhóm nhắn tả tình trạng của một thành viên trong nhóm, giọng lo lắng",
     "subjects": ["Bạn tôi", "Một bạn trong nhóm", "Anh ấy", "Cô ấy"]},
    {"id": "gen_z", "noise": 0.7,
     "desc": "người trẻ nhắn tin kiểu mạng xã hội, viết tắt, ít dấu câu, ít dấu tiếng Việt",
     "subjects": ["Em", "Tui", "Mình", "Tao"]},
    {"id": "nguoi_lon_tuoi", "noise": 0.1,
     "desc": "người lớn tuổi mô tả dài dòng, lịch sự, không dùng thuật ngữ chuyên môn",
     "subjects": ["Tôi", "Bác", "Chú", "Cô"]},
    {"id": "hoang_hot", "noise": 0.5,
     "desc": "người đang hoảng sợ, câu ngắn cụt, thiếu chủ ngữ, nhiều dấu chấm than",
     "subjects": ["Trời ơi tôi", "Giúp với, mình", "Cứu với, bạn tôi"]},
    {"id": "huong_dan_vien", "noise": 0.2,
     "desc": "hướng dẫn viên có kinh nghiệm báo cáo ngắn gọn, khách quan tình trạng của khách",
     "subjects": ["Khách", "Một khách", "Thành viên đoàn"]},
]
PERSONA_BY_ID = {p["id"]: p for p in PERSONAS}

GENERIC_CONTEXTS = [
    "đang đi trek", "đang cắm trại", "đang đi rừng", "đang ở trên núi",
    "giữa đường mòn", "ở khu suối", "đang đi bộ đường dài",
]


def _c(id, name, triage, explicit, banned, signs, conf, contexts=None, **extra):
    d = {
        "id": id, "name_vi": name, "triage": triage, "explicit_ok": explicit,
        "banned_terms": banned, "signs": signs, "confusable_with": conf,
        "signs_source": "seed - cần đối chiếu với nguồn chính thống",
    }
    if contexts:
        d["contexts"] = contexts
    d.update(extra)
    return d


# triage: emergency (khẩn cấp) | urgent (cần đi viện/hỗ trợ sớm) | self_care (tự xử lý) | none
# explicit_ok: người dùng thường tự nói ra tên sự cố (vd "bị rắn cắn") nên cho phép câu nêu tên
CONDITIONS = [
    _c("snakebite", "Rắn cắn", "emergency", True, ["rắn"],
       ["bị hai vết răng nhỏ trên da, chảy ít máu",
        "bị sưng đau tăng dần quanh vết cắn và lan lên chi",
        "thấy chóng mặt, buồn nôn sau khi bị thứ gì đó cắn",
        "bị sụp mí mắt, nhìn mờ hoặc nhìn đôi",
        "thấy tê môi, nói khó, nuốt khó",
        "bị bầm tím và phồng nước quanh chỗ bị cắn",
        "thấy khó thở, yếu cơ sau khi bị cắn"],
       ["insect_sting", "anaphylaxis"],
       ["đi qua bụi rậm", "đang đi rừng", "lúc đi trong bãi cỏ cao",
        "lúc lội qua suối", "đang cắm trại buổi tối"]),
    _c("heat_stroke", "Sốc nhiệt (say nắng nặng)", "emergency", False,
       ["say nắng", "sốc nhiệt", "đột quỵ nhiệt"],
       ["người nóng bừng, da đỏ và khô nóng",
        "bị lú lẫn, nói nhảm, không nhận ra mọi người",
        "bị co giật hoặc ngất xỉu giữa nắng",
        "thấy đau đầu dữ dội, nôn ói",
        "nhịp tim rất nhanh, thở gấp",
        "đi đứng loạng choạng, nói lắp"],
       ["heat_exhaustion", "hypoglycemia", "dehydration"],
       ["đang leo dốc giữa trưa nắng", "đi bộ dưới nắng gắt nhiều giờ",
        "đang trek ngày nóng ẩm", "khi chạy bộ đường mòn buổi trưa"]),
    _c("heat_exhaustion", "Kiệt sức do nóng", "urgent", False,
       ["kiệt sức do nóng", "say nắng", "mệt do nóng"],
       ["ra mồ hôi rất nhiều, da ẩm và hơi lạnh",
        "thấy mệt lả, chân tay yếu",
        "bị chóng mặt, hoa mắt khi đứng lên",
        "bị đau đầu, buồn nôn",
        "bị chuột rút ở bắp chân hoặc bụng",
        "da tái nhợt, mạch nhanh và yếu",
        "khát nước dữ dội"],
       ["heat_stroke", "dehydration"],
       ["đang leo dốc giữa trưa nắng", "đi bộ dưới nắng gắt nhiều giờ",
        "đang trek ngày nóng ẩm"]),
    _c("hypothermia", "Hạ thân nhiệt", "emergency", False, ["hạ thân nhiệt"],
       ["run bần bật không kiểm soát được",
        "nói líu lưỡi, nói không rõ",
        "đi loạng choạng, tay chân vụng về",
        "thấy buồn ngủ, lơ mơ, phản ứng chậm",
        "da lạnh ngắt, môi tím tái",
        "đã ngừng run nhưng người vẫn rất lạnh và lừ đừ",
        "ướt sũng và thấy lạnh thấu xương"],
       ["frostbite", "hypoglycemia", "altitude_sickness"],
       ["bị ướt mưa trên đỉnh núi lúc gió lớn", "sau khi bị ngã xuống suối nước lạnh",
        "đêm cắm trại trên núi cao rất lạnh", "đi bộ dưới mưa lạnh nhiều giờ"]),
    _c("frostbite", "Tê cóng (bỏng lạnh)", "urgent", False,
       ["tê cóng", "bỏng lạnh", "frostbite"],
       ["mất cảm giác ở ngón tay, ngón chân",
        "da ngón tay chuyển trắng hoặc xám vàng và cứng",
        "thấy tê buốt, ngứa nhói ở mũi hoặc tai",
        "da phồng rộp sau khi được làm ấm",
        "ngón chân lạnh cứng như gỗ"],
       ["hypothermia"],
       ["ở đỉnh núi gió rét", "cắm trại ở vùng núi cao dưới 0 độ", "đi trong tuyết nhiều giờ"]),
    _c("anaphylaxis", "Sốc phản vệ (dị ứng nặng)", "emergency", False,
       ["sốc phản vệ", "phản vệ", "dị ứng nặng"],
       ["nổi mề đay khắp người",
        "bị sưng môi, mí mắt, lưỡi hoặc mặt",
        "thở khò khè, tức cổ họng, khó thở",
        "thấy chóng mặt, choáng, muốn ngất",
        "nôn ói, đau bụng dữ dội sau khi bị đốt hoặc ăn thứ lạ",
        "tim đập nhanh, người nóng ran và ngứa dữ dội"],
       ["insect_sting", "snakebite", "plant_mushroom_poisoning"],
       ["sau khi bị ong đốt", "sau khi ăn thử quả lạ trong rừng",
        "sau khi ăn hải sản ở bãi biển", "lúc đang cắm trại"]),
    _c("insect_sting", "Côn trùng đốt/chích", "self_care", True, ["côn trùng"],
       ["bị đau nhói và sưng đỏ tại chỗ bị đốt",
        "thấy ngứa rát quanh vết đốt",
        "thấy có cái ngòi nhỏ cắm trên da",
        "bị nổi mẩn đỏ và hơi sưng",
        "bị sưng nhẹ nhưng vẫn thở bình thường"],
       ["anaphylaxis", "snakebite"],
       ["sau khi chạm vào tổ ong", "lúc ngồi nghỉ gần bụi cây",
        "khi đi qua khu có kiến lửa", "đang cắm trại"]),
    _c("leech_bite", "Đỉa/vắt cắn", "self_care", True, ["đỉa", "vắt"],
       ["phát hiện có con gì nhỏ bám trên chân và hút máu",
        "vết cắn chảy máu mãi không ngừng",
        "bị ngứa nhẹ ở chỗ có vết máu, không thấy đau",
        "thấy tất dính máu mà không biết bị gì",
        "thấy chỗ bị cắn hơi sưng đỏ"],
       ["minor_wound", "severe_bleeding"],
       ["đi qua rừng ẩm sau mưa", "lội qua suối trong rừng", "đi trong rừng nhiều lá mục"]),
    _c("severe_bleeding", "Chảy máu nặng", "emergency", True, ["chảy máu nặng", "mất máu"],
       ["máu chảy ồ ạt, thấm ướt hết băng",
        "máu phun thành tia từ vết thương",
        "ép mãi mà máu vẫn không cầm",
        "thấy choáng váng, da tái, vã mồ hôi lạnh sau khi bị thương",
        "bị vết cắt sâu và rộng ở tay hoặc chân",
        "bị vật nhọn đâm vào đùi, máu chảy nhiều"],
       ["minor_wound", "leech_bite", "fracture"],
       ["lúc chặt củi", "bị ngã trúng đá nhọn", "khi dùng dao nấu ăn ngoài trại",
        "sau khi té xe trên đường rừng"]),
    _c("minor_wound", "Vết thương nhỏ/trầy xước", "self_care", True, [],
       ["bị trầy da ở đầu gối, chảy máu ít",
        "bị cắt nhẹ ở ngón tay, máu gần ngừng",
        "bị xước dính bùn đất, đau rát",
        "bị rách da nhỏ do cành cây quẹt",
        "bị xây xát ở khuỷu tay sau khi trượt chân"],
       ["severe_bleeding", "leech_bite"],
       ["lúc đi qua bụi gai", "bị trượt chân trên đường mòn", "lúc leo qua tảng đá"]),
    _c("sprain", "Bong gân/trẹo cổ chân", "self_care", True, ["bong gân"],
       ["bị trẹo chân, cổ chân sưng và đau",
        "cổ chân bầm tím sau khi lật chân",
        "vẫn đứng được nhưng bước đi thì đau nhói",
        "khớp cổ tay sưng đau sau khi chống tay xuống đất",
        "nghe tiếng phựt rồi đau, sau đó sưng dần"],
       ["fracture"],
       ["xuống dốc trên đá trơn", "lúc bước hụt trên đường mòn", "đang băng qua suối đá"]),
    _c("fracture", "Gãy xương", "urgent", True, ["gãy xương"],
       ["thấy đau dữ dội, không dám cử động chi bị thương",
        "thấy tay hoặc chân bị cong lệch bất thường",
        "bị sưng nhanh và bầm tím lan rộng",
        "không thể đứng hoặc chịu lực lên chân",
        "nghe tiếng rắc khi ngã, giờ đau không chịu nổi",
        "thấy đầu xương nhô ra qua vết thương"],
       ["sprain", "spinal_injury", "severe_bleeding"],
       ["sau khi ngã từ tảng đá", "té xe trên đường đèo", "trượt chân ngã xuống dốc"]),
    _c("head_injury", "Chấn thương đầu", "urgent", True, ["chấn thương đầu", "chấn thương sọ não"],
       ["bị ngã đập đầu, sưng một cục lớn",
        "bị đau đầu tăng dần và nôn ói sau cú va đập",
        "thấy lơ mơ, hỏi gì cũng quên",
        "bị bất tỉnh một lúc rồi mới tỉnh lại",
        "bị chảy máu hoặc dịch trong ra từ tai hoặc mũi sau khi ngã",
        "có hai đồng tử to nhỏ không đều",
        "buồn ngủ liên tục và khó đánh thức"],
       ["spinal_injury", "altitude_sickness", "hypoglycemia"],
       ["bị đá lăn trúng đầu", "ngã đập đầu xuống đất khi leo núi",
        "va đầu vào cành cây khi đi đêm"]),
    _c("spinal_injury", "Chấn thương cột sống", "emergency", False, ["cột sống", "tủy sống"],
       ["sau cú ngã từ trên cao, bị đau cổ hoặc lưng dữ dội",
        "thấy tê hoặc kiến bò ở tay hoặc chân",
        "không cử động được chân tay sau khi ngã",
        "đau nhói khi xoay cổ, không dám cử động",
        "mất cảm giác từ thắt lưng trở xuống"],
       ["fracture", "head_injury"],
       ["ngã từ vách đá xuống", "bị đá lăn đè vào lưng", "tai nạn xe trên đường đèo",
        "nhảy xuống nước nông bị đập đầu"]),
    _c("burn", "Bỏng", "urgent", True, ["bỏng"],
       ["bị da đỏ rát, đau sau khi chạm vào bếp lửa",
        "bị phồng nước ở tay sau khi nước sôi đổ vào",
        "có vùng da cháy trắng hoặc đen, ít đau",
        "bị ống pô xe máy chạm vào bắp chân, da rát và phồng",
        "bị da bong tróc sau khi cháy nắng nặng"],
       ["blister", "lightning_strike"],
       ["lúc nấu ăn ngoài trời", "bên đống lửa trại", "khi đun nước bằng bếp gas mini"]),
    _c("blister", "Phồng rộp do cọ xát", "self_care", True, ["phồng rộp"],
       ["bị gót chân phồng nước do cọ giày",
        "thấy ngón chân đau rát, có bọng nước nhỏ",
        "thấy lòng bàn chân nóng rát sau khi đi bộ cả ngày",
        "bị bọng nước ở gót chân vỡ ra, rát",
        "thấy da ở mu bàn chân bị cọ đỏ rát"],
       ["burn", "minor_wound"],
       ["sau một ngày trek dài", "lúc đi giày mới", "khi lội bộ đường dài"]),
    _c("dehydration", "Mất nước", "urgent", False, ["mất nước"],
       ["khát khô cổ, miệng khô dính",
        "đi tiểu ít và nước tiểu sẫm màu",
        "thấy chóng mặt, mệt, đau đầu nhẹ",
        "da khô, môi nứt nẻ",
        "tim đập nhanh khi đứng lên",
        "đã nhiều giờ chưa đi tiểu"],
       ["heat_exhaustion", "heat_stroke", "diarrhea_food_poisoning"],
       ["hết nước uống từ sáng", "đi bộ cả ngày nắng nóng ít uống nước",
        "sau khi tiêu chảy nhiều"]),
    _c("diarrhea_food_poisoning", "Tiêu chảy/ngộ độc thực phẩm", "self_care", True,
       ["ngộ độc thực phẩm"],
       ["bị đau quặn bụng, đi ngoài nhiều lần",
        "buồn nôn và nôn sau bữa ăn trưa",
        "bị tiêu chảy sau khi uống nước suối chưa đun",
        "bị sốt nhẹ, người mệt, bụng sôi",
        "đi ngoài phân lỏng toàn nước"],
       ["dehydration", "plant_mushroom_poisoning"],
       ["sau khi ăn đồ nấu ngoài trại", "sau khi uống nước suối", "ngày thứ hai của chuyến trek"]),
    _c("plant_mushroom_poisoning", "Ngộ độc nấm/cây/quả rừng", "emergency", False,
       ["ngộ độc nấm", "ngộ độc"],
       ["nôn ói dữ dội sau khi ăn nấm hái trong rừng",
        "bị đau bụng, tiêu chảy sau khi ăn quả lạ",
        "thấy tê miệng, tê lưỡi sau khi nhai lá",
        "thấy chóng mặt, nhìn thấy ảo giác",
        "bị co giật hoặc lịm đi sau khi ăn thứ hái được",
        "mệt lả và đau bụng dữ dội vài giờ sau bữa nấm rừng"],
       ["diarrhea_food_poisoning", "anaphylaxis"],
       ["sau bữa nấu nấm hái ven đường mòn", "sau khi nếm quả lạ trong rừng",
        "sau khi ăn rau rừng nấu tại trại"]),
    _c("altitude_sickness", "Say độ cao", "urgent", False, ["say độ cao"],
       ["bị đau đầu, buồn nôn khi lên cao",
        "thấy mệt, chóng mặt, ngủ không yên trên núi cao",
        "thở hụt hơi cả khi nghỉ ngơi",
        "ho liên tục và tức ngực khi lên cao",
        "đi loạng choạng như say rượu, nói lú lẫn",
        "mất ngủ, ăn không ngon, nhức đầu từ khi lên trên 3000 mét"],
       ["hypothermia", "heat_exhaustion", "head_injury"],
       ["vừa lên độ cao hơn 3000 mét", "ngày thứ hai leo núi cao",
        "khi leo lên đỉnh núi cao liên tục"]),
    _c("drowning", "Đuối nước", "emergency", True, ["đuối nước"],
       ["bị chìm xuống nước, được vớt lên ho sặc sụa",
        "được kéo từ nước lên nhưng thở yếu hoặc không thở",
        "môi tím tái, không đáp lời sau khi bị chìm",
        "sặc nước nhiều, nôn ra nước và khó thở",
        "ngâm lâu dưới nước, bất tỉnh khi lên bờ"],
       ["hypothermia"],
       ["ở khu thác", "lúc tắm suối", "khi lật thuyền kayak", "ở bãi biển sóng lớn"]),
    _c("lightning_strike", "Sét đánh", "emergency", True, ["sét đánh"],
       ["bị sét đánh trúng hoặc ở rất gần chỗ sét đánh",
        "ngất đi rồi tỉnh lại, người tê dại",
        "có vết bỏng dạng cành cây trên da",
        "bị ù tai, nhìn mờ sau tiếng nổ lớn",
        "tim đập loạn, ngưng thở sau cú giật điện từ sét"],
       ["burn", "head_injury"],
       ["giữa cơn dông trên đỉnh đồi", "đứng dưới gốc cây cao khi mưa giông",
        "trên sườn núi trống trải lúc có sấm sét"]),
    _c("hypoglycemia", "Hạ đường huyết", "emergency", False, ["hạ đường huyết"],
       ["run tay, vã mồ hôi lạnh, đói cồn cào",
        "bị lú lẫn, nói năng lộn xộn dù không uống rượu",
        "thấy hoa mắt, tim đập nhanh khi nhịn đói đi bộ",
        "đang bị tiểu đường, trek cả ngày chưa ăn, giờ run và lơ mơ",
        "bất tỉnh hoặc co giật, trước đó rất đói"],
       ["heat_exhaustion", "hypothermia", "heat_stroke"],
       ["đi bộ cả buổi sáng chưa ăn gì", "sau khi tiêm insulin rồi leo dốc", "trek đường dài bỏ bữa"]),
    _c("choking", "Hóc/nghẹn dị vật đường thở", "emergency", True, ["hóc dị vật"],
       ["đang ăn thì ôm cổ, không nói được",
        "ho không ra tiếng, mặt tím dần",
        "thở rít, khò khè sau khi nuốt phải thức ăn",
        "không thở được, mặt đỏ rồi tái",
        "đang nhai thì bị nghẹn, tay chỉ vào cổ"],
       ["anaphylaxis"],
       ["trong bữa ăn ở trại", "lúc ăn vội bên đường mòn", "khi vừa ăn vừa đi"]),
    _c("unknown", "Không rõ / ngoài phạm vi", "none", False, [],
       ["thấy hơi mệt sau khi đi bộ",
        "bị đau đầu nhẹ",
        "hơi đau bụng một chút",
        "thấy hơi buồn ngủ",
        "bị nhức mỏi chân sau cả ngày đi bộ",
        "thấy hơi chán ăn",
        "bị ngứa nhẹ ở tay"],
       [],
       raw_phrases=["Nên mang theo những gì khi đi trek hai ngày?",
                    "Đường lên đỉnh dài bao nhiêu km vậy?",
                    "Tối nay trời có mưa không?",
                    "Cho mình hỏi chỗ nào cắm trại đẹp",
                    "Mệt quá", "Đau",
                    "Có ai biết suối gần đây không?",
                    "Mình đang thấy không khỏe nhưng không biết tả sao",
                    "Cách chọn giày đi rừng?",
                    "hôm nay đi bộ được 15 km rồi"]),
]

SOURCES_README = """Thư mục này chứa đoạn nguồn để sinh nội dung sơ cứu (lệnh first-aid).

Quy ước: mỗi tình huống một hoặc nhiều file  <condition_id>*.txt  (UTF-8), ví dụ:
  snakebite.txt
  heat_stroke_wms.txt
  heat_stroke_ifrc.txt

Nội dung: chép/tóm tắt các đoạn liên quan từ hướng dẫn chính thống (IFRC, ERC, WMS...).
Giữ nguyên ngôn ngữ gốc của nguồn (tiếng Anh cũng được) để cột "evidence" kiểm tra được.
Đây là tư liệu cá nhân phục vụ học tập: nếu nguồn có bản quyền, đừng đăng công khai các file này.
"""

# ---------------------------------------------------------------------------
# 2. Tiện ích chung
# ---------------------------------------------------------------------------


def read_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def write_json(p, obj):
    Path(p).parent.mkdir(parents=True, exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)


def read_jsonl(p):
    with open(p, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def write_jsonl(p, rows):
    Path(p).parent.mkdir(parents=True, exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")


def strip_diacritics(s: str) -> str:
    s = s.replace("đ", "d").replace("Đ", "D")
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


def norm_key(s: str) -> str:
    return " ".join(re.findall(r"[a-z0-9]+", strip_diacritics(s).lower()))


def norm_loose(s: str) -> str:
    """Chuẩn hoá để kiểm tra evidence nằm trong nguồn (giữ nguyên dấu)."""
    s = unicodedata.normalize("NFC", s).lower()
    return " ".join(re.sub(r"[^\w\s]", " ", s).split())


def clean_text(t: str) -> str:
    t = unicodedata.normalize("NFC", str(t)).strip()
    t = re.sub(r"^\s*(?:[-*•]|\d+[.)])\s+", "", t)
    return t.strip().strip('"“”').strip()


def near_dup_filter(rows, thr=0.85):
    """Loại câu trùng/gần trùng (Jaccard theo từ không dấu). Giữ câu đến trước."""
    kept, sigs = [], []
    for r in rows:
        toks = set(norm_key(r["text"]).split())
        if not toks:
            continue
        if any(len(toks & s) / len(toks | s) >= thr for s in sigs):
            continue
        kept.append(r)
        sigs.append(toks)
    return kept


ABBR = [("không", "ko"), ("được", "dc"), ("với", "vs"), ("bây giờ", "bh"),
        ("người", "ng"), ("rồi", "r"), ("quá", "wa"), ("làm sao", "lm sao")]


def add_noise(text: str, rng: random.Random, level: float):
    """Thêm nhiễu kiểu người dùng thật. Trả về (text, có_nhiễu)."""
    changed = False
    text = unicodedata.normalize("NFC", text)
    if rng.random() < level * 0.6:
        text, changed = text.lower(), True
    if rng.random() < level * 0.5:
        for a, b in ABBR:
            if rng.random() < 0.6:
                text = re.sub(rf"\b{re.escape(a)}\b", b, text, flags=re.I)
        changed = True
    if rng.random() < level * 0.4:
        words = text.split()
        idx = [i for i, w in enumerate(words) if len(w) >= 4]
        if idx:
            i = rng.choice(idx)
            w = words[i]
            k = rng.randrange(1, len(w) - 1)
            op = rng.choice(["swap", "drop", "dup"])
            if op == "swap":
                w = w[:k] + w[k + 1] + w[k] + w[k + 2:]
            elif op == "drop":
                w = w[:k] + w[k + 1:]
            else:
                w = w[:k + 1] + w[k] + w[k + 1:]
            words[i] = w
            text, changed = " ".join(words), True
    if rng.random() < level * 0.5:
        text, changed = re.sub(r"[.,!?;:]", "", text), True
    if rng.random() < level * 0.5:
        text, changed = strip_diacritics(text), True
    return unicodedata.normalize("NFC", text).strip(), changed


# ---------------------------------------------------------------------------
# 3. LLM helpers
# ---------------------------------------------------------------------------


def get_client():
    try:
        import anthropic
    except ImportError:
        sys.exit("Thiếu thư viện: pip install anthropic")
    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("Thiếu biến môi trường ANTHROPIC_API_KEY")
    return anthropic.Anthropic()


def llm_call(client, model, system, user, max_tokens=4000, retries=4):
    last = None
    for i in range(retries):
        try:
            r = client.messages.create(
                model=model, max_tokens=max_tokens, system=system,
                messages=[{"role": "user", "content": user}])
            return "".join(b.text for b in r.content if getattr(b, "type", "") == "text")
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 ** i)
    raise RuntimeError(f"Gọi API thất bại sau {retries} lần: {last}")


def parse_json(text):
    t = text.strip()
    t = re.sub(r"^```[a-zA-Z]*\s*|\s*```$", "", t).strip()
    try:
        return json.loads(t)
    except json.JSONDecodeError:
        pass
    cands = sorted((t.find(o), o, c) for o, c in (("[", "]"), ("{", "}")) if t.find(o) != -1)
    for i, _o, c in cands:
        j = t.rfind(c)
        if j > i:
            try:
                return json.loads(t[i:j + 1])
            except json.JSONDecodeError:
                continue
    raise ValueError("Không phân tích được JSON từ phản hồi")


# ---------------------------------------------------------------------------
# 4. Sinh câu triệu chứng (NHÃN -> TRIỆU CHỨNG)
# ---------------------------------------------------------------------------

SYSTEM_GEN = ("Bạn là công cụ sinh dữ liệu huấn luyện cho bộ phân loại tình huống sơ cứu khi đi dã ngoại. "
              "Chỉ trả về MỘT mảng JSON các chuỗi tiếng Việt, không giải thích, không đánh số.")

MODE_DESC = {
    "implicit": ("Người nhắn chỉ mô tả cảm giác/dấu hiệu quan sát được. TUYỆT ĐỐI không nêu tên tình huống "
                 "hay chẩn đoán (không dùng các từ như: {banned})."),
    "explicit": ("Người nhắn có thể tự nói ra điều đã xảy ra (nguyên nhân/sự cố) một cách tự nhiên, "
                 "như người không chuyên."),
    "partial": ("Người nhắn chỉ nêu 1-2 dấu hiệu, rất ngắn, thiếu thông tin; không nêu tên tình huống. "
                "Những dấu hiệu đó cũng có thể gặp ở: {conf}."),
}


def gen_prompt(cond, persona, ctx, mode, k, by_id):
    if cond["id"] == "unknown":
        ex = "\n".join(f"- {s}" for s in cond.get("raw_phrases", []))
        vague = "\n".join(f"- {s}" for s in cond["signs"])
        return (f"Viết {k} tin nhắn tiếng Việt của người đang đi dã ngoại KHÔNG thuộc nhóm cấp cứu/sơ cứu: "
                f"than phiền mơ hồ rất nhẹ, câu hỏi chung (chuẩn bị đồ, thời tiết, địa điểm), hoặc tin nhắn không "
                f"liên quan y tế.\nVí dụ than phiền nhẹ:\n{vague}\nVí dụ câu hỏi chung:\n{ex}\n"
                f"Vai trò người nhắn: {persona['desc']}. Bối cảnh: {ctx}.\n"
                f"Mỗi tin 2-30 từ, đa dạng. Trả về mảng JSON {k} chuỗi.")
    signs = "\n".join(f"- {s}" for s in cond["signs"])
    banned = ", ".join(cond.get("banned_terms", []) or [cond["name_vi"]])
    conf = ", ".join(by_id[c]["name_vi"] for c in cond.get("confusable_with", []) if c in by_id) \
        or "một số tình huống khác"
    rule = MODE_DESC[mode].format(banned=banned, conf=conf)
    return (f"Tình huống thật (nhãn): {cond['name_vi']}\n"
            f"Các dấu hiệu tham khảo (chỉ dùng một phần, diễn đạt lại bằng lời của người nhắn, không liệt kê đủ):\n"
            f"{signs}\n\nVai trò người nhắn: {persona['desc']}\nBối cảnh: {ctx}\nChế độ: {rule}\n\n"
            f"Viết {k} tin nhắn khác nhau, mỗi tin 5-40 từ, nhờ giúp đỡ hoặc kể tình trạng. "
            f"Không đưa lời khuyên xử lý, không chẩn đoán. Trả về mảng JSON {k} chuỗi.")


def llm_utterances(client, model, cond, n, batch_size, workers, rng, by_id):
    ctxs = cond.get("contexts") or GENERIC_CONTEXTS
    modes = ["implicit"] * 6 + ["partial"] * 2
    if cond.get("explicit_ok"):
        modes += ["explicit"] * 3
    if cond["id"] == "unknown":
        modes = ["implicit"]
    n_batches = math.ceil(n * 1.4 / batch_size)
    jobs = [(rng.choice(PERSONAS), rng.choice(ctxs), rng.choice(modes)) for _ in range(n_batches)]

    def run(job):
        persona, ctx, mode = job
        try:
            arr = parse_json(llm_call(client, model, SYSTEM_GEN,
                                      gen_prompt(cond, persona, ctx, mode, batch_size, by_id)))
        except Exception as e:  # noqa: BLE001
            print(f"  [cảnh báo] {cond['id']}: lỗi batch ({e})", file=sys.stderr)
            return []
        return [{"text": s, "persona": persona["id"], "context": ctx, "mode": mode}
                for s in arr if isinstance(s, str)]

    with ThreadPoolExecutor(max_workers=workers) as ex:
        return [c for batch in ex.map(run, jobs) for c in batch]


TEMPLATES = [
    "{subj} {body}.",
    "{ctx_cap}, {subj_l} {body}.",
    "{subj} {body}. Phải làm sao?",
    "{subj} {body}, giờ làm gì đây?",
    "{ctx_cap} thì {subj_l} {body}",
]


def template_utterances(cond, n, rng):
    """Backend không cần API: ghép dấu hiệu theo mẫu. Chỉ để chạy thử pipeline, KHÔNG thay cho LLM."""
    ctxs = cond.get("contexts") or GENERIC_CONTEXTS
    raws = cond.get("raw_phrases", [])
    out, tries = [], 0
    while len(out) < n and tries < n * 30:
        tries += 1
        persona = rng.choice(PERSONAS)
        ctx = rng.choice(ctxs)
        if raws and rng.random() < 0.4:
            out.append({"text": rng.choice(raws), "persona": persona["id"],
                        "context": ctx, "mode": "template"})
            continue
        k = rng.choice([1, 1, 2, 2, 3])
        picked = rng.sample(cond["signs"], min(k, len(cond["signs"])))
        body = rng.choice([" và ", ", ", ", rồi "]).join(picked)
        subj = rng.choice(persona["subjects"])
        text = rng.choice(TEMPLATES).format(
            subj=subj, subj_l=subj[0].lower() + subj[1:], body=body,
            ctx_cap=ctx[0].upper() + ctx[1:])
        out.append({"text": text, "persona": persona["id"], "context": ctx,
                    "mode": "template_partial" if len(picked) == 1 else "template"})
    return out


def finalize(cands, cond, n, rng):
    banned = [b.lower() for b in cond.get("banned_terms", [])]
    ok = []
    for c in cands:
        t = clean_text(c["text"])
        if not 3 <= len(t) <= 400:
            continue
        if c["mode"] == "implicit" and any(b in t.lower() for b in banned):
            continue  # câu "không nêu tên" mà vẫn lộ tên -> bỏ
        ok.append({**c, "text": t})
    rng.shuffle(ok)
    ok = near_dup_filter(ok)[:n]
    rows = []
    for c in ok:
        text, noisy = add_noise(c["text"], rng, PERSONA_BY_ID[c["persona"]]["noise"])
        rows.append({"text": text, "condition_id": cond["id"], "persona": c["persona"],
                     "context": c["context"], "mode": c["mode"], "noisy": noisy})
    return rows


# ---------------------------------------------------------------------------
# 5. Các lệnh
# ---------------------------------------------------------------------------


def load_conditions(out):
    p = Path(out) / "conditions.json"
    if not p.exists():
        sys.exit(f"Chưa có {p}. Hãy chạy: python generate_dataset.py init")
    return read_json(p)


def cmd_init(a):
    out = Path(a.out)
    p = out / "conditions.json"
    if p.exists() and not a.force:
        sys.exit(f"{p} đã tồn tại (dùng --force để ghi đè)")
    write_json(p, CONDITIONS)
    (out / "sources").mkdir(parents=True, exist_ok=True)
    (out / "sources" / "README.txt").write_text(SOURCES_README, encoding="utf-8")
    print(f"Đã tạo {p} ({len(CONDITIONS)} nhãn) và thư mục {out / 'sources'}/")
    print("Hãy đối chiếu 'signs' với nguồn chính thống và chỉnh danh mục cho phù hợp ứng dụng.")


def cmd_utterances(a):
    rng = random.Random(a.seed)
    conds = load_conditions(a.out)
    by_id = {c["id"]: c for c in conds}
    bad = [x for x in (a.labels or []) if x not in by_id]
    if bad:
        sys.exit(f"Nhãn không tồn tại: {bad}")
    client = get_client() if a.backend == "llm" else None
    gen_name = f"llm:{a.model}" if a.backend == "llm" else "template"
    targets = [c for c in conds if not a.labels or c["id"] in a.labels]
    new_rows = []
    print(f"Sinh dữ liệu bằng backend={a.backend} ...")
    for cond in targets:
        n = a.unknown_count if cond["id"] == "unknown" else a.per_label
        if a.backend == "template":
            cands = template_utterances(cond, n * 2, rng)
        else:
            cands = llm_utterances(client, a.model, cond, n, a.batch_size, a.workers, rng, by_id)
        rows = finalize(cands, cond, n, rng)
        for r in rows:
            r["generator"] = gen_name
        flag = "" if len(rows) >= n else "   <-- thiếu, hãy chạy lại với --labels " + cond["id"]
        print(f"  {cond['id']:<26} {len(rows):>4}/{n}{flag}")
        new_rows += rows
    raw = Path(a.out) / "utterances_raw.jsonl"
    if a.labels and raw.exists():
        keep = [r for r in read_jsonl(raw) if r["condition_id"] not in set(a.labels)]
        new_rows = keep + new_rows
    for i, r in enumerate(new_rows, 1):
        r["id"] = f"u{i:06d}"
    write_jsonl(raw, new_rows)
    print(f"Đã ghi {len(new_rows)} dòng -> {raw}")


def blind_tfidf(rows, seed, folds=5):
    try:
        from sklearn.feature_extraction.text import TfidfVectorizer
        from sklearn.linear_model import LogisticRegression
        from sklearn.model_selection import StratifiedKFold, cross_val_predict
        from sklearn.pipeline import make_pipeline
    except ImportError:
        sys.exit("Thiếu scikit-learn: pip install scikit-learn  (hoặc dùng --method llm)")
    X = [strip_diacritics(r["text"]).lower() for r in rows]
    y = [r["condition_id"] for r in rows]
    folds = max(2, min(folds, min(Counter(y).values())))
    pipe = make_pipeline(TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 5), sublinear_tf=True),
                         LogisticRegression(max_iter=2000))
    proba = cross_val_predict(pipe, X, y, method="predict_proba",
                              cv=StratifiedKFold(folds, shuffle=True, random_state=seed))
    classes = sorted(set(y))
    res = []
    for p in proba:
        order = sorted(range(len(classes)), key=lambda i: -p[i])[:3]
        res.append([(classes[i], float(p[i])) for i in order])
    return res


def blind_llm(client, model, rows, conds, workers, batch=20):
    ids = {c["id"] for c in conds}
    label_list = "\n".join(f"- {c['id']}: {c['name_vi']} (ví dụ: {'; '.join(c['signs'][:2])})" for c in conds)
    system = "Bạn phân loại tin nhắn cầu cứu khi đi dã ngoại. Chỉ trả về một đối tượng JSON."

    def run(chunk):
        start, items = chunk
        listing = "\n".join(f"{i}: {r['text']}" for i, r in enumerate(items))
        user = (f"Danh sách nhãn:\n{label_list}\n\nVới mỗi tin nhắn, chọn TỐI ĐA 2 nhãn khả dĩ nhất "
                f"(nhãn khả dĩ nhất đứng trước). Dùng 'unknown' nếu không thuộc nhóm nào.\n\n{listing}\n\n"
                'Trả về JSON dạng {"0": ["id1", "id2"], "1": ["id1"], ...}')
        try:
            obj = parse_json(llm_call(client, model, system, user, max_tokens=3000))
        except Exception as e:  # noqa: BLE001
            print(f"  [cảnh báo] lỗi batch judge ({e})", file=sys.stderr)
            return [[] for _ in items]
        out = []
        for i in range(len(items)):
            v = obj.get(str(i), []) if isinstance(obj, dict) else []
            v = [x for x in (v if isinstance(v, list) else [v]) if x in ids]
            out.append([(x, None) for x in v])
        return out

    chunks = [(i, rows[i:i + batch]) for i in range(0, len(rows), batch)]
    with ThreadPoolExecutor(max_workers=workers) as ex:
        return [r for part in ex.map(run, chunks) for r in part]


def cmd_filter(a):
    rows = read_jsonl(Path(a.out) / "utterances_raw.jsonl")
    conds = load_conditions(a.out)
    if a.method == "tfidf":
        results = blind_tfidf(rows, a.seed)
    else:
        results = blind_llm(get_client(), a.judge_model, rows, conds, a.workers)
    clean, suspect = [], []
    for r, preds in zip(rows, results):
        k = 2 if r["mode"] in ("partial", "template_partial") else 1
        top = [c for c, _ in preds[:k]]
        conf = preds[0][1] if preds and preds[0][1] is not None else None
        wrong = r["condition_id"] not in top
        if a.method == "tfidf":
            wrong = wrong and conf is not None and conf >= a.conf
        if a.method == "llm" and not preds:
            wrong = False  # judge không trả lời -> không kết luận
        if wrong:
            suspect.append({**r, "judge_top": [c for c, _ in preds], "judge_conf": conf})
        else:
            clean.append(r)
    write_jsonl(Path(a.out) / "utterances_clean.jsonl", clean)
    write_jsonl(Path(a.out) / "utterances_suspect.jsonl", suspect)
    print(f"Giữ lại {len(clean)} / {len(rows)} dòng; nghi ngờ {len(suspect)} dòng "
          f"-> utterances_suspect.jsonl (hãy đọc thử vài chục dòng)")
    by = Counter((s["condition_id"], s["judge_top"][0] if s["judge_top"] else "?") for s in suspect)
    for (gold, pred), cnt in by.most_common(10):
        print(f"  nhãn gốc {gold:<24} bị đoán là {pred:<24} x{cnt}   (gợi ý cặp dễ nhầm)")


def cmd_split(a):
    out = Path(a.out)
    src = out / "utterances_clean.jsonl"
    if not src.exists():
        print("[cảnh báo] chưa có utterances_clean.jsonl, dùng utterances_raw.jsonl (chưa lọc)")
        src = out / "utterances_raw.jsonl"
    rows = read_jsonl(src)
    hold = set(a.holdout_persona or [])
    bad = [h for h in hold if h not in PERSONA_BY_ID]
    if bad:
        sys.exit(f"Persona không tồn tại: {bad}. Có: {list(PERSONA_BY_ID)}")
    labels_of = defaultdict(set)
    for r in rows:
        labels_of[norm_key(r["text"])].add(r["condition_id"])
    conflict = {k for k, v in labels_of.items() if len(v) > 1}
    rows = [r for r in rows if norm_key(r["text"]) not in conflict]
    grouped = defaultdict(list)
    for r in rows:
        grouped[r["condition_id"]].append(r)
    rng = random.Random(a.seed)
    final, n_dup = [], 0
    for cid in sorted(grouped):
        rs = grouped[cid]
        rng.shuffle(rs)
        before = len(rs)
        rs = near_dup_filter(rs)
        n_dup += before - len(rs)
        held = [r for r in rs if r["persona"] in hold]
        held_ids = {r["id"] for r in held}
        rest = [r for r in rs if r["id"] not in held_ids]
        n_val = round(len(rest) * a.val_frac)
        n_test = 0 if hold else round(len(rest) * a.test_frac)
        for i, r in enumerate(rest):
            r["split"] = "val" if i < n_val else "test" if i < n_val + n_test else "train"
        for r in held:
            r["split"] = "test"
        final += rest + held
    final.sort(key=lambda r: r["id"])
    write_jsonl(out / "utterances.jsonl", final)
    stats = {"total": len(final), "dropped_conflict_texts": len(conflict), "dropped_near_dup": n_dup,
             "holdout_persona": sorted(hold), "per_label": {}}
    print(f"{'nhãn':<28}{'train':>7}{'val':>7}{'test':>7}")
    for cid in sorted(grouped):
        c = Counter(r["split"] for r in final if r["condition_id"] == cid)
        stats["per_label"][cid] = dict(c)
        print(f"{cid:<28}{c['train']:>7}{c['val']:>7}{c['test']:>7}")
    write_json(out / "stats.json", stats)
    print(f"Tổng {len(final)} dòng -> {out / 'utterances.jsonl'} | bỏ {len(conflict)} câu mâu thuẫn nhãn, "
          f"{n_dup} câu gần trùng")
    print("Nhắc lại: tập test cuối cùng nên gồm câu VIẾT TAY (eval_real.jsonl), không do cùng LLM sinh.")


FA_SYSTEM = """Bạn chuyển đoạn hướng dẫn sơ cứu (NGUỒN) thành dữ liệu có cấu trúc bằng tiếng Việt.
Quy tắc bắt buộc:
1. Chỉ dùng thông tin có trong NGUỒN. Không thêm kiến thức ngoài, không suy đoán.
2. Mỗi mục kèm "evidence": trích NGUYÊN VĂN một đoạn ngắn (tối đa 25 từ) từ NGUỒN, giữ đúng ngôn ngữ của nguồn.
3. Không ghi tên thuốc hay liều lượng. Nếu nguồn có nhắc, bỏ qua và ghi tóm tắt vào "omitted".
4. Nếu nguồn không nói về một mục, trả mảng rỗng cho mục đó.
5. Câu ngắn, dạng mệnh lệnh, dễ làm theo khi đang hoảng.
6. Chỉ trả về một đối tượng JSON, không giải thích."""

FA_SCHEMA = ('{"red_flags": [{"text": "...", "evidence": "..."}], '
             '"steps": [{"text": "...", "evidence": "..."}], '
             '"do_not": [{"text": "...", "evidence": "..."}], '
             '"evacuate_if": [{"text": "...", "evidence": "..."}], '
             '"omitted": ["..."]}')
FA_SECTIONS = ["red_flags", "steps", "do_not", "evacuate_if"]


def check_items(client, model, source, record):
    flat = [(sec, i, it) for sec in FA_SECTIONS for i, it in enumerate(record.get(sec, []))]
    for _s, _i, it in flat:
        it["evidence_ok"] = bool(it.get("evidence")) and norm_loose(it["evidence"]) in norm_loose(source)
    if not flat:
        return
    listing = "\n".join(f"{n}: {it.get('text', '')}" for n, (_s, _i, it) in enumerate(flat))
    system = "Bạn kiểm tra tính trung thực của nội dung so với nguồn. Chỉ trả về JSON."
    user = (f"NGUỒN:\n<<<\n{source[:12000]}\n>>>\n\nVới mỗi mục đánh số dưới đây, cho biết: "
            f"supported (nguồn nói rõ), unsupported (nguồn không đề cập), contradicted (nguồn nói ngược).\n\n"
            f"{listing}\n\nTrả về JSON: [{{\"i\": 0, \"verdict\": \"supported\", \"note\": \"...\"}}, ...]")
    try:
        arr = parse_json(llm_call(client, model, system, user, max_tokens=3000))
    except Exception as e:  # noqa: BLE001
        print(f"  [cảnh báo] kiểm tra chéo lỗi ({e})", file=sys.stderr)
        arr = []
    verdicts = {v.get("i"): v for v in arr if isinstance(v, dict)}
    for n, (_s, _i, it) in enumerate(flat):
        v = verdicts.get(n, {})
        it["check"] = v.get("verdict", "unchecked")
        it["check_note"] = v.get("note", "")


def cmd_first_aid(a):
    conds = [c for c in load_conditions(a.out) if c["id"] != "unknown"]
    client = get_client()
    src_dir = Path(a.out) / "sources"
    result, missing = {}, []
    for c in conds:
        if a.labels and c["id"] not in a.labels:
            continue
        files = sorted(src_dir.glob(f"{c['id']}*.txt"))
        if not files:
            missing.append(c["id"])
            continue
        source = "\n\n".join(f.read_text(encoding="utf-8") for f in files)
        user = (f"Tình huống: {c['name_vi']} (id: {c['id']}, mức khẩn cấp: {c['triage']})\n\n"
                f"NGUỒN:\n<<<\n{source[:12000]}\n>>>\n\nTrả về JSON đúng dạng:\n{FA_SCHEMA}")
        try:
            rec = parse_json(llm_call(client, a.model, FA_SYSTEM, user, max_tokens=4000))
        except Exception as e:  # noqa: BLE001
            print(f"  [lỗi] {c['id']}: {e}", file=sys.stderr)
            continue
        for sec in FA_SECTIONS:
            rec[sec] = [x for x in rec.get(sec, []) if isinstance(x, dict)]
        check_items(client, a.judge_model, source, rec)
        rec.update({"condition_id": c["id"], "name_vi": c["name_vi"], "triage": c["triage"],
                    "sources": [f.name for f in files], "generator": a.model,
                    "judge": a.judge_model, "review_status": "draft",
                    "reviewed_by": None, "reviewed_on": None})
        result[c["id"]] = rec
        items = [it for s in FA_SECTIONS for it in rec[s]]
        good = sum(1 for it in items if it.get("check") == "supported" and it.get("evidence_ok"))
        print(f"  {c['id']:<26} {good}/{len(items)} mục có nguồn hỗ trợ")
    write_json(Path(a.out) / "first_aid_draft.json", result)
    print(f"Đã ghi {len(result)} bản nháp -> first_aid_draft.json (review_status = draft)")
    if missing:
        print(f"Chưa có file nguồn cho: {', '.join(missing)}  (đặt vào {src_dir}/<id>.txt)")
    print("Việc tiếp theo: tự đọc từng mục, sửa/loại mục bị flag, rồi đổi review_status -> 'reviewed' "
          "và lưu thành first_aid.json")


def cmd_validate(a):
    out = Path(a.out)
    errs, warns = [], []
    conds = load_conditions(a.out)
    ids = [c["id"] for c in conds]
    if len(ids) != len(set(ids)):
        errs.append("conditions.json có id trùng")
    idset = set(ids)
    up = out / "utterances.jsonl"
    if up.exists():
        rows = read_jsonl(up)
        cnt = Counter((r["condition_id"], r["split"]) for r in rows)
        for r in rows:
            if r["condition_id"] not in idset:
                errs.append(f"utterances: nhãn lạ '{r['condition_id']}' ({r['id']})")
            if r["split"] not in ("train", "val", "test"):
                errs.append(f"utterances: split lạ '{r['split']}' ({r['id']})")
        for cid in ids:
            if cnt[(cid, "train")] == 0:
                errs.append(f"nhãn '{cid}' không có mẫu train")
            elif cnt[(cid, "train")] < a.min_train:
                warns.append(f"nhãn '{cid}' chỉ có {cnt[(cid, 'train')]} mẫu train (< {a.min_train})")
            if cnt[(cid, "test")] == 0:
                warns.append(f"nhãn '{cid}' không có mẫu test")
        seen = {}
        leaks = 0
        for r in rows:
            k = norm_key(r["text"])
            if k in seen and seen[k] != r["split"]:
                leaks += 1
            seen.setdefault(k, r["split"])
        if leaks:
            errs.append(f"{leaks} câu trùng nhau nhưng nằm ở split khác nhau (rò rỉ dữ liệu)")
    else:
        warns.append("chưa có utterances.jsonl (chạy utterances -> filter -> split)")
    fa_path = out / "first_aid.json"
    if not fa_path.exists():
        fa_path = out / "first_aid_draft.json"
        if fa_path.exists():
            warns.append("đang kiểm tra first_aid_draft.json (chưa có first_aid.json đã duyệt)")
    if fa_path.exists():
        fa = read_json(fa_path)
        for cid in fa:
            if cid not in idset:
                errs.append(f"first_aid: id '{cid}' không có trong conditions.json")
        for cid in ids:
            if cid != "unknown" and cid not in fa:
                warns.append(f"first_aid: thiếu bản ghi cho '{cid}'")
        for cid, rec in fa.items():
            bad = [it for s in FA_SECTIONS for it in rec.get(s, [])
                   if it.get("check") != "supported" or not it.get("evidence_ok")]
            if bad:
                warns.append(f"first_aid[{cid}]: {len(bad)} mục chưa được nguồn xác nhận")
            if rec.get("review_status") != "reviewed":
                warns.append(f"first_aid[{cid}]: review_status = {rec.get('review_status')}")
            if not rec.get("steps"):
                warns.append(f"first_aid[{cid}]: không có bước sơ cứu nào")
    else:
        warns.append("chưa có first_aid (chạy first-aid)")
    for w in warns:
        print("[cảnh báo]", w)
    for e in errs:
        print("[LỖI]", e)
    print(f"Kết quả: {len(errs)} lỗi, {len(warns)} cảnh báo")
    sys.exit(1 if errs else 0)


# ---------------------------------------------------------------------------
# 6. CLI
# ---------------------------------------------------------------------------


def build_parser():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="data", help="thư mục dữ liệu (mặc định: data)")
    ap.add_argument("--seed", type=int, default=42)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("init", help="tạo conditions.json mẫu")
    p.add_argument("--force", action="store_true")
    p.set_defaults(fn=cmd_init)

    p = sub.add_parser("utterances", help="sinh câu triệu chứng")
    p.add_argument("--backend", choices=["llm", "template"], default="template")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--per-label", type=int, default=300)
    p.add_argument("--unknown-count", type=int, default=300)
    p.add_argument("--batch-size", type=int, default=10)
    p.add_argument("--workers", type=int, default=4)
    p.add_argument("--labels", nargs="*", help="chỉ sinh lại các nhãn này (giữ nguyên nhãn khác)")
    p.set_defaults(fn=cmd_utterances)

    p = sub.add_parser("filter", help="phân loại mù để lọc câu sai nhãn")
    p.add_argument("--method", choices=["tfidf", "llm"], default="tfidf")
    p.add_argument("--judge-model", default=DEFAULT_JUDGE)
    p.add_argument("--conf", type=float, default=0.5, help="(tfidf) ngưỡng tin cậy để coi là bất đồng")
    p.add_argument("--workers", type=int, default=4)
    p.set_defaults(fn=cmd_filter)

    p = sub.add_parser("split", help="khử trùng lặp + chia train/val/test")
    p.add_argument("--val-frac", type=float, default=0.1)
    p.add_argument("--test-frac", type=float, default=0.1)
    p.add_argument("--holdout-persona", nargs="*",
                   help=f"persona chỉ dùng cho test. Có: {', '.join(PERSONA_BY_ID)}")
    p.set_defaults(fn=cmd_split)

    p = sub.add_parser("first-aid", help="sinh bản nháp sơ cứu từ nguồn + kiểm tra chéo")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--judge-model", default=DEFAULT_JUDGE)
    p.add_argument("--labels", nargs="*")
    p.set_defaults(fn=cmd_first_aid)

    p = sub.add_parser("validate", help="kiểm tra tính nhất quán")
    p.add_argument("--min-train", type=int, default=50)
    p.set_defaults(fn=cmd_validate)
    return ap


def main(argv=None):
    a = build_parser().parse_args(argv)
    a.fn(a)


if __name__ == "__main__":
    main()