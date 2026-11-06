# Jogo Sobrevivência

Projeto Godot 4.2+ com a versão original 2D preservada e um protótipo 3D experimental na branch `feature/mundo-3d-selvagem`.

## Abrir o projeto
1. Baixe a branch pelo botão **Code (Código) → Download ZIP**.
2. Extraia a pasta e abra o Godot 4.2 ou superior.
3. Use **Importar (Import)** e selecione `project.godot`.
4. Para a versão original, pressione **F5 (Executar Projeto / Run Project)**.
5. Para o protótipo 3D, abra `scenes/wilderness_3d.tscn` e pressione **F6 (Executar Cena Atual / Run Current Scene)**.

## Controles do protótipo 3D
- **WASD**: movimentar.
- **E**: coletar recurso próximo.
- **Espaço**: ação de ataque do jogo.
- **ESC**: cancelar o modo de construção.
- **Celular**: joystick virtual e botões COLETAR, ATACAR, PAREDE, BASE e COLOCAR.

## Sistemas 3D incluídos
- Floresta procedural, câmera isométrica e colisões físicas nas árvores.
- Malha de navegação gerada em tempo de execução a partir do chão e dos troncos.
- Lobos, ursos e javalis com NavigationAgent3D, desvio por navegação/avoidance, patrulha, perseguição e vida.
- Coleta de madeira, pedra e fibra integrada ao inventário global do GameManager.
- HUD com vida, fome, sede e contagem dos recursos.
- Construção inicial em grade: paredes e fundações, com prévia translúcida, validação de espaço e custo de materiais.
- Controles por toque para celular.

## Construção 3D
- **PAREDE** inicia a prévia de uma parede; **BASE** inicia uma fundação.
- No computador, mova o mouse até o local desejado e clique no mundo para posicionar.
- No celular, toque em **COLOCAR** para posicionar à frente do personagem.
- Parede: 4 madeiras.
- Fundação: 3 madeiras e 2 pedras.
- **ESC** cancela a prévia.

As peças usam uma grade de 2 metros. A construção é um primeiro sistema funcional, ainda sem rotação, níveis de melhoria ou salvamento persistente das peças.

## Preservação da versão original
A cena principal `res://scenes/main.tscn` e os sistemas 2D não foram substituídos. O protótipo 3D continua isolado nesta branch até passar pelos testes.

## Estado de validação
As alterações foram gravadas no GitHub. **Ainda não foi possível executar o Godot nesta sessão**, pois o editor/engine não está disponível no ambiente de trabalho. Portanto, não afirmamos que os scripts estejam livres de erros. Abra a cena 3D no Godot 4.2+ e verifique as abas **Saída (Output)** e **Depurador (Debugger)**. A geração da navegação ocorre quando a cena inicia e pode levar alguns instantes.
