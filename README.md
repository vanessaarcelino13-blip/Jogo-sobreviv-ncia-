# Jogo Sobrevivência

Projeto original 2D para **Godot 4.2+**, com uma experiência experimental 3D adicionada em uma branch separada para preservar os sistemas existentes.

## Versão 2D existente
A cena principal continua sendo `res://scenes/main.tscn`. Ela mantém inventário, coleta, construção, clima, estações, animais e salvamento.

### Como abrir
1. Baixe o ZIP pelo botão **Code (Código) → Download ZIP** no GitHub.
2. Extraia a pasta.
3. Abra o Godot 4.2 ou superior.
4. Selecione **Importar (Import)** e escolha `project.godot`.
5. Pressione **F5 (Executar Projeto)**.

### Controles 2D
- **WASD**: movimentar.
- **E**: coletar recursos e interagir.
- **Q**: pulso de proteção.
- **I**: abrir mochila.
- **ESC**: cancelar posicionamento de construção.

## Protótipo 3D de sobrevivência selvagem
Na branch `feature/mundo-3d-selvagem` foi adicionada uma cena experimental independente: `res://scenes/wilderness_3d.tscn`.

Para testar:
1. Abra o projeto no Godot.
2. No painel **Sistema de arquivos (FileSystem)**, abra `scenes/wilderness_3d.tscn`.
3. Pressione **F6 (Executar Cena Atual)**.

### Controles 3D
- **WASD**: movimentar o sobrevivente em relação à câmera.
- **E**: coletar recursos próximos.

### O que já existe no protótipo 3D
- Cenário 3D de floresta com iluminação e câmera isométrica ortográfica.
- Personagem 3D com movimentação e colisão.
- Animais selvagens de teste: lobo, urso e javali, com patrulha simples, perseguição e ataque por proximidade.
- Recursos 3D de madeira, pedra e fibra com coleta por proximidade.

### Limites desta etapa
Esta é uma base experimental jogável, não uma conversão completa do jogo 2D. Os modelos são formas provisórias; ainda faltam navegação dos animais com NavigationRegion3D/NavigationAgent3D, animações, combate completo, inventário integrado ao 3D, construção 3D, controles táteis e testes no dispositivo. A cena principal 2D foi mantida para não perder os sistemas existentes.

## Sistemas 2D já presentes
- Mundo procedural com vegetação, pedras e solo.
- Inventário em grade com 20 espaços e pilhas limitadas.
- Coleta de madeira, pedra, fibras e couro.
- Ferramentas, roupas e receitas de fabricação.
- Ciclo de dia/noite, estações, clima e biomas.
- Construção com grade, custos e salvamento.
- Baús e armazenamento persistente.
- Salvamento local em JSON.

## Validação
A cena 3D foi adicionada ao repositório, mas precisa ser executada no editor Godot 4.2+ para validar a renderização e o comportamento no dispositivo de destino. Esta branch não inclui APK exportado.
