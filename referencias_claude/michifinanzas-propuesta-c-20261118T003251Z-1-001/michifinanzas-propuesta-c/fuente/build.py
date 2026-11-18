"""Arma ../index.html a partir de plantilla.html y los scripts de esta carpeta.
Uso: python build.py   (desde cualquier carpeta)"""
from pathlib import Path
aqui = Path(__file__).resolve().parent
leer = lambda n: (aqui / n).read_text(encoding='utf-8')
src = leer('plantilla.html')
app = leer('app.js').replace('/*MODULES_4B*/', leer('mod4b.js')).replace('/*SHEETS_4B*/', leer('sheets4b.js'))
partes = {'/*VENDOR*/': leer('react-bundle.js'), '/*HTM*/': leer('htm-lite.js'), '/*CATS*/': leer('cats.js'), '/*APP*/': app}
for marca, texto in partes.items():
    assert src.count(marca) == 1, marca
    src = src.replace(marca, texto.replace('</script', '<\\/script'))
(aqui.parent / 'index.html').write_text(src, encoding='utf-8')
print('index.html generado:', len(src.encode()), 'bytes')
