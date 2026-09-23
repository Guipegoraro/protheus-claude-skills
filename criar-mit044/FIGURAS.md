# Figuras da MIT044

Mecânica do passo 5 da [`SKILL.md`](SKILL.md). Toda figura é um PNG em `mit-figuras/` na pasta
do plano, referenciado no JSON por `{"tipo": "imagem", "src": "mit-figuras/<nome>.png",
"legenda": "Figura N: ...", "largura_cm": 16}`. Largura útil máxima 17,5 cm; 15 a 16 cm para
fluxograma e protótipo, menos para figura estreita (o gerador mantém a proporção).

## Fluxograma

HTML autocontido, renderizado e capturado como os protótipos. Paleta do documento: texto
`#1F4E79`, caixas com fundo `#DCE6F1`, fonte Verdana. Spine vertical de nós numerados na ordem
dos passos de `execucao.fluxo`; desvios de exceção como caixas laterais ligadas ao nó de origem
(vermelho rejeição, cinza ignorado, amarelo atenção). Nó com uma frase curta, sem jargão.

## Captura via chrome-devtools

- Capturar com a tela preenchida: clicar nos botões de simulação antes.
- `display:none` inline é desfeito pelo re-render da página; injetar uma tag
  `<style id="...">` com `!important` para esconder barra de simulação e notas.
- `fullPage: true` dá timeout com página em background; usar screenshot de viewport com
  `body { zoom: X }` para caber, com a página trazida à frente (`select_page` com
  `bringToFront`).

## Recorte

Recortar bordas brancas com System.Drawing: scan de pixels não brancos mais padding de
~10 px, salvar como PNG. Conferir o resultado com o Read antes de referenciar no JSON.
