# FORMA — Virtual Eyewear Studio

A static eyewear storefront demo with a live virtual try-on fitting room. Visitors can browse sample frames, filter the collection, switch frame styles, and preview glasses on a live camera feed.

## Try it locally

Serve this repository root with a static web server, then open its URL in a browser. For example:

```bash
python -m http.server 8000
```

Open http://localhost:8000. Camera access requires a secure context, such as localhost or an HTTPS deployment. A plain HTTP address on a local network may not be permitted to access a phone's camera.

## Try-on flow

1. Select a frame from the collection or the carousel.
2. Choose **Open the fitting room**.
3. Allow camera access in the browser.
4. Switch styles while the face tracker positions the selected frame.

The demo processes the camera feed in the browser. It does not record or upload video. Face tracking loads MediaPipe Tasks Vision and its model from external CDNs when the camera is enabled, so an internet connection is required.

## GitHub Pages

The site is a single static `index.html`. In the repository, open **Settings → Pages**, choose **Deploy from a branch**, select `main` and `/(root)`, then save. GitHub will provide an HTTPS page URL after deployment.

## Demo catalog

Frame names, product descriptions, and prices are sample content. Replace them with the real inventory before using this as a live store.
