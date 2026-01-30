# コロコロコミック NIKKE RSS対応設計

## 概要

週刊コロコロコミックの「勝利の女神：NIKKE すいーとえんかうんと」をRSSフィード対応する。

## サイト分析

- **URL**: https://www.corocoro.jp/title/29
- **技術スタック**: Next.js (SPA)
- **エピソード形式**: 本編（第N話）＋特別イラスト
- **URLパターン**: `/comment/{id}` (相対パス)
- **日付形式**: `YYYY/MM/DD`

## DOM構造

```
ul.divide-y
  └── li
      ├── img[alt="第1話  の話サムネイル"]  ← タイトル取得元
      ├── a[href="/comment/4934"]           ← URL取得元
      └── (テキスト内に日付 2023/11/29)     ← 日付取得元
```

## 実装方針

- **モード**: JavaScript評価モード（extraction_script使用）
- **コード変更**: 不要（既存のbase_url対応で完結）
- **設定追加**: `config/sites.yml`のみ

## 設定

```yaml
- name: "勝利の女神：NIKKE すいーとえんかうんと"
  id: "corocoro-nikke"
  url: "https://www.corocoro.jp/title/29"
  base_url: "https://www.corocoro.jp"
  user_agent: "Mozilla/5.0 ..."
  wait_seconds: 5
  extraction_script: (詳細はsites.yml参照)
```

## 出力

- `output/corocoro-nikke.xml`
