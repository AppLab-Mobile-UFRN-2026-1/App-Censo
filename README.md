# 🏙️ App-Censo

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

O **App-Censo** é um aplicativo mobile desenvolvido em Flutter para o cadastro, o mapeamento e o acompanhamento georreferenciado de solicitações e obras públicas.

A plataforma busca promover maior transparência e eficiência na gestão da infraestrutura urbana, permitindo que cidadãos e gestores registrem problemas estruturais, acompanhem intervenções governamentais e consultem informações atualizadas diretamente em um mapa interativo.

O nome **App-Censo** representa o levantamento contínuo das condições de infraestrutura dos municípios, funcionando como um censo colaborativo e georreferenciado de demandas e obras públicas.

---

## 📸 Demonstração

> Video após a implementação das principais interfaces.

---

## 🎯 Objetivo

O principal objetivo do aplicativo é disponibilizar uma plataforma colaborativa para o mapeamento de demandas urbanas e a fiscalização do andamento de obras públicas.

Por meio do georreferenciamento, da captura fotográfica em tempo real e do consumo de uma API real, o sistema permitirá registrar e acompanhar ocorrências relacionadas a:

* Pavimentação danificada;
* Falhas na iluminação pública;
* Problemas de saneamento;
* Estruturas públicas deterioradas;
* Obras públicas em início, andamento ou conclusão;
* Outras necessidades de infraestrutura municipal.

---

## ✨ Funcionalidades

### 🔐 Autenticação e Conta

* **Cadastro de Usuário:** criação de conta por meio de endereço de e-mail e senha.
* **Login de Usuário:** autenticação de usuários previamente cadastrados.
* **Manutenção de Sessão:** armazenamento local da sessão para reconhecer usuários já autenticados.
* **Logout:** encerramento seguro da sessão atual.
* **Validação de Formulários:** verificação de campos obrigatórios, formato de e-mail, senha e demais dados informados.

### 🗺️ Mapa e Geolocalização

* **Mapa Interativo:** tela principal com visualização das ocorrências cadastradas.
* **Localização Atual:** identificação da posição geográfica do usuário e centralização automática do mapa.
* **Marcadores Personalizados:** diferenciação visual entre solicitações de obra e obras em execução.
* **Detalhamento de Ocorrências:** exibição de fotografia, descrição, categoria ou estágio, status, município, estado e data do registro.
* **Georreferenciamento:** associação de latitude e longitude a cada ocorrência cadastrada.
* **Identificação de Localidade:** preenchimento automático de município e estado com base na posição geográfica.

### 📷 Cadastro de Solicitações e Obras

* **Captura Fotográfica Obrigatória:** uso da câmera do dispositivo para registrar o local no momento do cadastro.
* **Bloqueio de Arquivos da Galeria:** o registro deve utilizar uma fotografia capturada em tempo real.
* **Solicitação de Obra:** cadastro de problemas de infraestrutura com categoria, descrição, fotografia e localização.
* **Obra em Execução:** cadastro de intervenções públicas com estágio atual, descrição, fotografia e localização.
* **Envio para API:** comunicação com uma API real para salvar e recuperar os registros.
* **Feedback de Operação:** indicação visual dos estados de carregamento, sucesso e erro durante o envio dos dados.

### 💾 Persistência Local

* **Sessão Persistente:** manutenção dos dados essenciais de autenticação no dispositivo.
* **Preferências do Usuário:** armazenamento de informações necessárias para melhorar a experiência de uso.
* **Recuperação de Estado:** preservação de dados importantes durante a navegação e reinicialização do aplicativo.

---

## 📱 Fluxo de Navegação

1. **Splash:** verifica se existe uma sessão válida salva no dispositivo.
2. **Login:** autentica o usuário por e-mail e senha.
3. **Cadastro:** cria uma nova conta.
4. **Mapa:** apresenta a localização atual e as ocorrências cadastradas.
5. **Nova Ocorrência:** permite registrar uma solicitação ou obra em execução.
6. **Detalhes da Ocorrência:** apresenta todas as informações de um ponto selecionado.
7. **Perfil ou Configurações:** disponibiliza informações do usuário e a opção de logout.

## 💻 Pré-requisitos

Antes de começar, instale:

* [Git](https://git-scm.com);
* [Flutter SDK](https://docs.flutter.dev/get-started/install);
* [Android Studio](https://developer.android.com/studio) ou [Visual Studio Code](https://code.visualstudio.com);
* Android SDK e um emulador configurado, ou um dispositivo físico com depuração USB ativada;
* Xcode, caso o projeto seja executado em um dispositivo iOS;
* Uma chave ou configuração válida para o serviço de mapas adotado;
* Acesso à API utilizada pelo projeto.

Para verificar a configuração do ambiente:

```bash
flutter doctor
```

---

## 🚀 Como executar o projeto

1. Clone o repositório:

   ```bash
   git clone https://github.com/leonardonadson/App-Censo.git
   ```

2. Acesse a pasta do projeto:

   ```bash
   cd App-Censo
   ```

3. Instale as dependências:

   ```bash
   flutter pub get
   ```

4. Configure as variáveis e credenciais necessárias para a API e o serviço de mapas.

5. Conecte um dispositivo físico ou inicie um emulador.

6. Execute o aplicativo:

   ```bash
   flutter run
   ```

---

## 👥 Equipe de Desenvolvimento

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/leonardonadson">
        <img src="https://avatars.githubusercontent.com/leonardonadson" width="100px;" alt="Foto de Leonardo Nadson no GitHub"/>
        <br>
        <sub>
          <b>Leonardo Nadson</b>
        </sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/luan-sampaio">
        <img src="https://avatars.githubusercontent.com/luan-sampaio" width="100px;" alt="Foto de Luan Sampaio no GitHub"/>
        <br>
        <sub>
          <b>Luan Sampaio</b>
        </sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/MarcusAurelius33">
        <img src="https://avatars.githubusercontent.com/MarcusAurelius33" width="100px;" alt="Foto de Marcus Aurelius no GitHub"/>
        <br>
        <sub>
          <b>Marcus Aurelius</b>
        </sub>
      </a>
    </td>
  </tr>
</table>
