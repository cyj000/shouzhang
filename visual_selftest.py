#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""手账记账 App · 视觉专项无环境自测脚本（视觉任务书 VPKG-06）。

无 Android SDK / Xcode 环境下最大化自测：
  S1 静态结构：Token 文件完整性、硬编码色值/魔法数、主题接入
  S2 逻辑校验：WCAG 对比度计算（纯 Python）
  S3 素材合规：字体声明与授权凭证存在性、动效开关存在性

用法：
  python visual_selftest.py                       # 仅校验内置 Token 色对与结构规则
  python visual_selftest.py --src <工程根路径>     # 扫描真实工程
  python visual_selftest.py --src <path> --json    # 输出 JSON 报告

退出码：0 = 全部 PASS；1 = 存在 FAIL（WARN 不影响退出码）。
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from typing import Optional

# ---------------------------------------------------------------------------
# Token 色值（与 lib/core/theme/app_colors.dart 保持同步；改色须同步此处并重跑）
# ---------------------------------------------------------------------------
TOKENS = {
    "paperBg": "FBF3E4",
    "paperCard": "FFFCF5",
    "inkPrimary": "6B4F3A",
    "inkSecondary": "756552",
    "accentCoral": "C4663E",
    "accentMint": "6B8A5F",
    "accentCoralDeep": "A34F2B",
    "onPrimary": "FFFFFF",
}

# (名称, 前景 Token, 背景 Token, 最低倍数, 是否大字阈值 3:1)
COLOR_PAIRS = [
    ("inkPrimary on paperBg (正文/金额)", "inkPrimary", "paperBg", 4.5, False),
    ("inkPrimary on paperCard (卡片正文)", "inkPrimary", "paperCard", 4.5, False),
    ("inkSecondary on paperBg (次要信息)", "inkSecondary", "paperBg", 4.5, False),
    ("onPrimary on accentCoralDeep (主按钮白字)", "onPrimary", "accentCoralDeep", 4.5, False),
    ("accentCoral on paperBg (大字/图形)", "accentCoral", "paperBg", 3.0, True),
    ("accentMint on paperBg (大字/图形)", "accentMint", "paperBg", 3.0, True),
]

# 业务代码允许出现的系统色白名单（系统 UI / 语义，非主题色）
COLOR_NAME_WHITELIST = {"transparent"}
# 允许出现色值字面量的文件（唯一事实源）
COLOR_LITERAL_ALLOWED_FILES = {"app_colors.dart"}
# 业务目录硬编码魔法数扫描范围（这些目录禁止魔法数）
MAGIC_SCAN_DIRS = ("lib/features", "lib/shared")
# 允许魔法数的例外模式：绘图纸笔参数等插画内部值由白名单文件豁免
MAGIC_WHITELIST_FILES = set()


@dataclass
class CheckResult:
    category: str
    name: str
    status: str  # PASS / FAIL / WARN
    detail: str = ""


@dataclass
class Report:
    results: list[CheckResult] = field(default_factory=list)

    def add(self, category: str, name: str, ok: bool, detail: str = "",
            warn: bool = False) -> None:
        status = "WARN" if warn and not ok else ("PASS" if ok else "FAIL")
        self.results.append(CheckResult(category, name, status, detail))

    @property
    def failed(self) -> bool:
        return any(r.status == "FAIL" for r in self.results)

    def counts(self) -> dict[str, int]:
        out = {"PASS": 0, "FAIL": 0, "WARN": 0}
        for r in self.results:
            out[r.status] = out.get(r.status, 0) + 1
        return out


# ---------------------------------------------------------------------------
# WCAG 2.1 对比度计算
# ---------------------------------------------------------------------------
def _hex_to_rgb(hexstr: str) -> tuple[int, int, int]:
    h = hexstr.strip().lstrip("#")
    if len(h) == 8:  # AARRGGBB -> 取 RGB
        h = h[2:]
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def _linear(c8: int) -> float:
    c = c8 / 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def luminance(hexstr: str) -> float:
    r, g, b = (_linear(v) for v in _hex_to_rgb(hexstr))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(fg: str, bg: str) -> float:
    l1, l2 = luminance(fg), luminance(bg)
    hi, lo = (l1, l2) if l1 > l2 else (l2, l1)
    return (hi + 0.05) / (lo + 0.05)


# ---------------------------------------------------------------------------
# 检查项
# ---------------------------------------------------------------------------
def check_contrast(rep: Report) -> None:
    for name, fg_tok, bg_tok, threshold, _ in COLOR_PAIRS:
        ratio = contrast_ratio(TOKENS[fg_tok], TOKENS[bg_tok])
        rep.add(
            "S2-对比度",
            name,
            ratio >= threshold,
            f"{ratio:.2f}:1 (需 ≥{threshold})",
        )


def check_tokens_from_source(rep: Report, src: str) -> None:
    """核对源码 app_colors.dart 中的色值与脚本内置 Token 一致，防漂移。"""
    path = os.path.join(src, "lib", "core", "theme", "app_colors.dart")
    if not os.path.isfile(path):
        rep.add("S1-结构", "app_colors.dart 存在", False, path)
        return
    text = open(path, encoding="utf-8").read()
    mismatches = []
    for tok, hexval in TOKENS.items():
        m = re.search(
            rf"\bColor\s+{tok}\s*=\s*(?:const\s+)?Color\(0x([0-9A-Fa-f]{{8}})\)",
            text,
        )
        if not m:
            mismatches.append(f"{tok}:未找到")
        elif m.group(1).upper()[-6:] != hexval.upper():
            mismatches.append(f"{tok}:源码{m.group(1)[-6:]}≠脚本{hexval}")
    rep.add(
        "S1-结构",
        "源码 Token 色值与脚本一致",
        not mismatches,
        "全部一致" if not mismatches else "; ".join(mismatches),
    )


def _iter_dart_files(src: str):
    lib_dir = os.path.join(src, "lib")
    for root, _dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith(".dart"):
                yield root, f


def check_hardcoded_colors(rep: Report, src: str) -> None:
    hits: list[str] = []
    for root, fname in _iter_dart_files(src):
        if fname in COLOR_LITERAL_ALLOWED_FILES:
            continue
        full = os.path.join(root, fname)
        rel = os.path.relpath(full, src).replace("\\", "/")
        for lineno, line in enumerate(open(full, encoding="utf-8"), 1):
            if re.search(r"Color\(\s*0x", line):
                hits.append(f"{rel}:{lineno}: Color(0x...)")
            for m in re.finditer(r"\bColors\.([A-Za-z]+)", line):
                if m.group(1) not in COLOR_NAME_WHITELIST:
                    hits.append(f"{rel}:{lineno}: Colors.{m.group(1)}")
    rep.add(
        "S1-硬编码",
        "业务代码无硬编码色值",
        not hits,
        "零命中" if not hits else f"{len(hits)} 处: " + ", ".join(hits[:12]),
    )


def check_magic_numbers(rep: Report, src: str) -> None:
    hits: list[str] = []
    patterns = [
        (r"fontSize\s*:\s*\d+", "fontSize 魔法数"),
        (r"BorderRadius\.circular\(\s*\d+", "BorderRadius 魔法数"),
    ]
    for sub in MAGIC_SCAN_DIRS:
        base = os.path.join(src, *sub.split("/"))
        if not os.path.isdir(base):
            continue
        for root, _dirs, files in os.walk(base):
            for fname in files:
                if not fname.endswith(".dart") or fname in MAGIC_WHITELIST_FILES:
                    continue
                full = os.path.join(root, fname)
                rel = os.path.relpath(full, src).replace("\\", "/")
                for lineno, line in enumerate(open(full, encoding="utf-8"), 1):
                    for pat, label in patterns:
                        if re.search(pat, line):
                            hits.append(f"{rel}:{lineno}: {label}")
    rep.add(
        "S1-硬编码",
        "业务代码无字号/圆角魔法数",
        not hits,
        "零命中" if not hits else f"{len(hits)} 处: " + ", ".join(hits[:12]),
    )


def check_theme_wiring(rep: Report, src: str) -> None:
    app = os.path.join(src, "lib", "app.dart")
    if not os.path.isfile(app):
        rep.add("S1-结构", "MaterialApp 接入主题", False, "缺 lib/app.dart")
        return
    text = open(app, encoding="utf-8").read()
    ok = "AppTheme.light()" in text
    rep.add("S1-结构", "MaterialApp.theme = AppTheme.light()", ok,
            "已接入" if ok else "未接入")


def check_token_files(rep: Report, src: str) -> None:
    required = [
        "lib/core/theme/app_colors.dart",
        "lib/core/theme/app_typography.dart",
        "lib/core/theme/app_shape.dart",
        "lib/core/theme/app_motion.dart",
        "lib/core/theme/paper_texture.dart",
        "lib/core/theme/app_theme.dart",
        "lib/shared/decor/tape_strip.dart",
        "lib/shared/decor/sticker_frame.dart",
        "lib/shared/decor/empty_state_art.dart",
    ]
    missing = [p for p in required if not os.path.isfile(os.path.join(src, *p.split("/")))]
    rep.add("S1-结构", "9 个 Token/decor 文件齐全", not missing,
            "齐全" if not missing else "缺失: " + ", ".join(missing))


def check_motion_switch(rep: Report, src: str) -> None:
    motion = os.path.join(src, "lib", "core", "theme", "app_motion.dart")
    settings = os.path.join(src, "lib", "features", "settings", "settings_page.dart")
    m_ok = os.path.isfile(motion) and "motionEnabledProvider" in open(
        motion, encoding="utf-8").read()
    s_ok = os.path.isfile(settings) and "motionEnabledProvider" in open(
        settings, encoding="utf-8").read()
    rep.add("S3-合规", "全局动效开关存在且接入设置页", m_ok and s_ok,
            f"app_motion={m_ok}, settings={s_ok}")


def check_font_license(rep: Report, src: str) -> None:
    pubspec = os.path.join(src, "pubspec.yaml")
    license_doc = os.path.join(src, "docs", "visual_asset_licenses.md")
    ofl = os.path.join(src, "assets", "fonts", "OFL.txt")
    ttf = os.path.join(src, "assets", "fonts", "LXGWWenKai-Regular.ttf")
    pub_ok = os.path.isfile(pubspec) and "fonts:" in open(
        pubspec, encoding="utf-8").read()
    rep.add("S3-合规", "pubspec 字体声明", pub_ok, "存在 fonts: 段" if pub_ok else "缺失")
    doc_ok = os.path.isfile(license_doc) and os.path.getsize(license_doc) > 0
    rep.add("S3-合规", "字体授权凭证登记", doc_ok,
            "docs/visual_asset_licenses.md" if doc_ok else "缺失")
    asset_ok = os.path.isfile(ofl) and os.path.isfile(ttf) and os.path.getsize(ttf) > 1000000
    rep.add("S3-合规", "字体文件与 OFL 随包", asset_ok,
            "TTF + OFL 存在" if asset_ok else "字体文件/OFL 缺失")


def check_sticker_count(rep: Report, src: str) -> None:
    catalog = os.path.join(src, "lib", "features", "sticker", "sticker_catalog.dart")
    if not os.path.isfile(catalog):
        rep.add("S1-结构", "贴纸 ≥20 款", False, "缺 sticker_catalog.dart")
        return
    text = open(catalog, encoding="utf-8").read()
    count = len(re.findall(r"BuiltinSticker\(", text))
    rep.add("S1-结构", "内置贴纸 ≥20 款", count >= 20, f"实际 {count} 款")


def run(src: Optional[str]) -> Report:
    rep = Report()
    check_contrast(rep)
    if src:
        if not os.path.isdir(src):
            print(f"错误：--src 路径不存在: {src}", file=sys.stderr)
            sys.exit(2)
        check_tokens_from_source(rep, src)
        check_token_files(rep, src)
        check_hardcoded_colors(rep, src)
        check_magic_numbers(rep, src)
        check_theme_wiring(rep, src)
        check_motion_switch(rep, src)
        check_font_license(rep, src)
        check_sticker_count(rep, src)
    else:
        rep.add("S1-结构", "源码扫描", True, "未提供 --src，跳过（仅校验 Token 对比度）", warn=True)
    return rep


def print_text(rep: Report) -> None:
    print("=" * 72)
    print(" 手账 App · 视觉专项无环境自测报告")
    print("=" * 72)
    cur = None
    for r in rep.results:
        if r.category != cur:
            cur = r.category
            print(f"\n[{cur}]")
        mark = {"PASS": "[PASS]", "FAIL": "[FAIL]", "WARN": "[WARN]"}[r.status]
        print(f"  {mark} {r.name}" + (f"  -- {r.detail}" if r.detail else ""))
    c = rep.counts()
    print("\n" + "-" * 72)
    print(f" 汇总: PASS={c['PASS']}  FAIL={c['FAIL']}  WARN={c['WARN']}")
    print(f" 结论: {'FAIL — 存在未通过项' if rep.failed else 'PASS — 全部通过'}")
    print("-" * 72)


def main() -> int:
    ap = argparse.ArgumentParser(description="视觉专项无环境自测")
    ap.add_argument("--src", help="Flutter 工程根路径")
    ap.add_argument("--json", action="store_true", help="输出 JSON")
    args = ap.parse_args()
    rep = run(args.src)
    if args.json:
        payload = {
            "counts": rep.counts(),
            "failed": rep.failed,
            "results": [r.__dict__ for r in rep.results],
        }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print_text(rep)
    return 1 if rep.failed else 0


if __name__ == "__main__":
    sys.exit(main())
