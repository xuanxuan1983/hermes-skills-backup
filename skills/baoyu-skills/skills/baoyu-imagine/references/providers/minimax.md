# MiniMax

Read when the user picks `--provider minimax` or sets `default_model.minimax`. Default model is `image-01`.

## Models

**`image-01`** (recommended default)

- Supports text-to-image and subject-reference image generation
- Supports official `aspect_ratio` values: `1:1`, `16:9`, `4:3`, `3:2`, `2:3`, `3:4`, `9:16`, `21:9`
- Supports documented custom `width` / `height` via `--size <WxH>`
- Both width and height must be in `[512, 2048]` and divisible by `8`

**`image-01-live`** — lower-latency variant

- Use `--ar` for sizing; MiniMax documents custom `width`/`height` only for `image-01`

## Subject Reference

- `--ref` files are sent as MiniMax `subject_reference`
- `subject_reference[].type` is currently `character`
- Official docs say `image_file` supports public URLs or Base64 Data URLs; baoyu-imagine sends local refs as Data URLs
- Recommended refs: front-facing portraits, JPG/JPEG/PNG, under 10MB

## API Key

**Important**: MiniMax image generation (`image-01`) requires a separate API key from the chat/chat completion key. A key that works for `MiniMax-M2.7` or `MiniMax-M2.1` chat models does NOT work for image generation.

Get your image-specific key at: https://platform.minimax.io/ → API Keys → Create a new key with Image Generation permissions.

**Endpoint**: `https://api.minimaxi.com/v1` (not `api.minimax.com`)

**Verify key works for images**:
```bash
curl -s "https://api.minimaxi.com/v1/models" \
  -H "Authorization: Bearer YOUR_KEY"
```
Look for `image-01` or `image-01-live` in the response. If only chat models appear, the key lacks image permissions.

## Official References

- [Image Generation Guide](https://platform.minimax.io/docs/guides/image-generation)
- [Text-to-Image API](https://platform.minimax.io/docs/api-reference/image-generation-t2i)
- [Image-to-Image API](https://platform.minimax.io/docs/api-reference/image-generation-i2i)
