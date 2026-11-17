package com.paperledger.app.preflight

import android.content.ContentProvider
import android.content.ContentValues
import android.content.UriMatcher
import android.database.Cursor
import android.net.Uri

/**
 * ContentProvider 骨架（FR-40 / REV-08 / DQ-06）。
 *
 * 【做】声明 + exported=false + signature 权限 + 空实现（返回 null/0）。
 * 【不做】授权同意页 / token / 审计 / 网关 / 实际数据查询 —— 一期无确定第三方（I-1）。
 * 外部应用无法访问（exported=false），不构成数据外泄面（R1）。
 */
class LedgerContentProvider : ContentProvider() {

    private val uriMatcher = UriMatcher(UriMatcher.NO_MATCH).apply {
        // 仅预埋 URI 匹配骨架，不返回任何数据。
        addURI(AUTHORITY, "entries", CODE_ENTRIES)
    }

    override fun onCreate(): Boolean = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null // 一期不开放任何数据

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    companion object {
        private const val AUTHORITY = "com.paperledger.app.provider"
        private const val CODE_ENTRIES = 1
    }
}
