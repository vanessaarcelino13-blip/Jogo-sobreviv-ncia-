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
Na branch `feature/mundo-3d-selvagem` existe uma cena experimental independente: `res://scenes/wilderness_3d.tscn`.

Para testar:
1. Abra o projeto no Godot.
2. No painel **Sistema de arquivos (FileSystem)**, abra `scenes/wilderness_3d.tscn`.
3. Pressione **F6 (Executar Cena Atual)**.

### Controles 3D
- **WASD**: movimentar o sobrevivente em relação à câmera.
- **E**: coletar recursos próximos.
- **Espaço**: atacar o animal mais próximo.
- **Celular**: joystick virtual no canto inferior esquerdo; botões **COLETAR** e **ATACAR** no canto inferior direito.

### Sistemas já ligados no protótipo 3D
- Floresta 3D com iluminação, câmera isométrica e colisão do solo.
- Personagem 3D com movimentação, colisão e vida ligada ao GameManager.
- HUD com vida, fome, sede e resumo dos itens da mochila.
- Consumo gradual de fome e sede usando o sistema de sobrevivência existente.
- Coleta de madeira, pedra e fibra integrada ao inventário global de 20 espaços.
- Quantidade de madeira/pedra respeita a ferramenta equipada no GameManager.
- Animais selvagens: lobo, urso e javali, com patrulha, perseguição, ataque, vida e recompensa de couro.
- Combate básico por proximidade e controles de toque para celular.

### Limites desta etapa
Esta ainda é uma base experimental, não uma conversão completa do jogo 2D. Os modelos são formas provisórias; ainda faltam navegação com obstáculos por NavigationRegion3D/NavigationAgent3D, animações, construção 3D, painel visual completo da mochila, balanceamento e testes no dispositivo de destino. A cena principal 2D foi mantida para preservar os sistemas já existentes.

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
As alterações foram gravadas no GitHub, mas não foram executadas no editor Godot nesta sessão. É necessário abrir a cena 3D no Godot 4.2+ e testar no computador/celular antes de considerar esta versão validada. Esta branch não inclui APK exportado.
