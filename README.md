# Jogo Sobrevivência

Projeto 2D para **Godot 4.2+**, com renderização Compatibility.

## Como abrir
1. Baixe o ZIP pelo botão **Code (Código) → Download ZIP** no GitHub.
2. Extraia a pasta.
3. Abra o Godot 4.2 ou superior.
4. Selecione **Importar (Import)** e escolha o arquivo `project.godot`.
5. Pressione **F6/F5 (Executar Cena/Projeto)**.

## Controles
- **WASD**: movimentar.
- **E**: coletar recursos e interagir.
- **Q**: pulso de proteção que afasta animais.
- **I**: abrir mochila.
- **ESC**: cancelar posicionamento de construção.

## Sistemas presentes
- Mundo procedural com detalhes de vegetação, pedras e solo.
- Personagem top-down com lanterna dinâmica via PointLight2D.
- Inventário em grade com 20 espaços e pilhas limitadas.
- Coleta de madeira, pedra, fibras e couro.
- Ferramentas, roupas e receitas de fabricação.
- Ciclo de dia/noite, estações e clima.
- Biomas com efeitos de clima.
- Construção com grade, custos e salvamento.
- Área de construção limitada à base (raio de 260 unidades a partir do centro).
- Baús e armazenamento persistente.
- Sistema de salvamento local em JSON.

## Validação
Os arquivos foram atualizados no GitHub. A execução dentro do editor Godot deve ser feita para confirmar compatibilidade visual e funcionamento no dispositivo de destino. Este repositório não inclui APK exportado.
