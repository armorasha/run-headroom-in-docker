FROM python:3.12-slim
RUN pip install --no-cache-dir \
    headroom-ai \
    headroom-ai[proxy]

# Inject a favicon into the vendored dashboard template — it ships with no <link rel="icon">.
COPY assets/favicon.svg /tmp/favicon.svg
RUN python3 -c "\
import base64, pathlib; \
svg = pathlib.Path('/tmp/favicon.svg').read_bytes(); \
b64 = base64.b64encode(svg).decode(); \
tpl = pathlib.Path('/usr/local/lib/python3.12/site-packages/headroom/dashboard/templates/dashboard.html'); \
html = tpl.read_text(); \
icon = f'<link rel=\"icon\" type=\"image/svg+xml\" href=\"data:image/svg+xml;base64,{b64}\">'; \
html = html.replace('<title>Headroom Dashboard</title>', '<title>Headroom Dashboard</title>\n    ' + icon); \
tpl.write_text(html)"

EXPOSE 8787
CMD ["headroom", "proxy", "--host", "0.0.0.0"]
