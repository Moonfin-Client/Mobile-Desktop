import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../l10n/app_localizations.dart';

class PluginWebSettingsScreen extends StatefulWidget {
  final Uri configurationPageUri;
  final String serverBaseUrl;
  final String accessToken;
  final String? userId;
  final String title;

  const PluginWebSettingsScreen({
    super.key,
    required this.configurationPageUri,
    required this.serverBaseUrl,
    required this.accessToken,
    this.userId,
    required this.title,
  });

  @override
  State<PluginWebSettingsScreen> createState() => _PluginWebSettingsScreenState();
}

class _PluginWebSettingsScreenState extends State<PluginWebSettingsScreen> {
  WebViewController? _controller;
  late final TextEditingController _addressController;
  late Uri _currentConfigurationPageUri;
  bool _isLoading = true;
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  bool get _supportsEmbeddedWebView {
    return !kIsWeb && WebViewPlatform.instance != null;
  }

  @override
  void initState() {
    super.initState();
    _currentConfigurationPageUri = widget.configurationPageUri;
    _addressController = TextEditingController(text: _currentConfigurationPageUri.toString());

    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final resolved = _resolvePluginConfigurationUri(request.url);
              if (resolved != null) {
                _currentConfigurationPageUri = resolved;
                _addressController.text = resolved.toString();
                _loadPluginConfigHtml(targetUri: resolved);
                return NavigationDecision.prevent;
              }

              return NavigationDecision.navigate;
            },
            onPageStarted: (url) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _addressController.text = url;
              });
            },
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress);
            },
            onPageFinished: (url) async {
              if (!mounted) return;
              _addressController.text = url;
              await _refreshNavigationState();
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        );

      _loadPluginConfigHtml(targetUri: _currentConfigurationPageUri);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _refreshNavigationState() async {
    final controller = _controller;
    if (controller == null) return;

    final canBack = await controller.canGoBack();
    final canForward = await controller.canGoForward();
    if (!mounted) return;

    setState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  Future<void> _goToAddress() async {
    final controller = _controller;
    if (controller == null) return;

    final raw = _addressController.text.trim();
    if (raw.isEmpty) return;

    var uri = Uri.tryParse(raw);
    if (uri == null || (!uri.hasScheme && !raw.startsWith('/'))) {
      uri = Uri.tryParse('https://$raw');
    }

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminPluginSettingsInvalidUrl)),
      );
      return;
    }

    final resolved = _resolvePluginConfigurationUri(uri.toString());
    if (resolved != null) {
      _currentConfigurationPageUri = resolved;
      _addressController.text = resolved.toString();
      await _loadPluginConfigHtml(targetUri: resolved);
      return;
    }

    await controller.loadRequest(uri);
  }

  Uri? _resolvePluginConfigurationUri(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) {
      return null;
    }

    final lowerRaw = rawUrl.toLowerCase();
    if (!lowerRaw.contains('configurationpage')) {
      return null;
    }

    String queryString = parsed.query;
    if (queryString.isEmpty && parsed.fragment.isNotEmpty) {
      final fragment = parsed.fragment;
      final lowerFragment = fragment.toLowerCase();
      final configIndex = lowerFragment.indexOf('configurationpage');
      if (configIndex >= 0) {
        final questionIndex = fragment.indexOf('?', configIndex);
        if (questionIndex >= 0 && questionIndex < fragment.length - 1) {
          queryString = fragment.substring(questionIndex + 1);
        }
      }
    }

    if (queryString.isEmpty || !RegExp(r'(^|&)name=', caseSensitive: false).hasMatch(queryString)) {
      return null;
    }

    return Uri.parse(widget.serverBaseUrl)
        .resolve('/web/ConfigurationPage?$queryString');
  }

  Future<void> _loadPluginConfigHtml({Uri? targetUri}) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final configUri = targetUri ?? _currentConfigurationPageUri;
    _currentConfigurationPageUri = configUri;

    setState(() {
      _isLoading = true;
      _progress = 0;
    });

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(configUri);
      request.headers.set('X-Emby-Token', widget.accessToken);
      request.headers.set('Accept', 'text/html');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Failed to load plugin configuration page (${response.statusCode})',
        );
      }

      final html = await utf8.decoder.bind(response).join();
      final wrappedHtml = _injectApiShim(html);

      await controller.loadHtmlString(
        wrappedHtml,
        baseUrl: configUri.toString(),
      );

      if (mounted) {
        setState(() {
          _addressController.text = configUri.toString();
          _isLoading = false;
          _progress = 100;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminPluginSettingsLoadFailed(e.toString()))),
      );

      setState(() {
        _isLoading = false;
      });
    } finally {
      httpClient.close(force: true);
    }
  }

  String _injectApiShim(String originalHtml) {
    final base = jsonEncode(widget.serverBaseUrl);
    final token = jsonEncode(widget.accessToken);
    final userId = jsonEncode(widget.userId ?? '');

    const shim = r'''
<script>
(function () {
  const serverBase = __SERVER_BASE__;
  const token = __TOKEN__;
  const currentUserId = __USER_ID__;

  function localize(key, fallback) {
    const lang = ((navigator.language || 'en').toLowerCase()).split('-')[0];
    const dict = {
      settingsSaved: {
        en: 'Settings saved',
        es: 'Configuracion guardada',
        fr: 'Parametres enregistres',
        de: 'Einstellungen gespeichert',
        it: 'Impostazioni salvate',
        pt: 'Configuracoes salvas',
        nl: 'Instellingen opgeslagen',
        sv: 'Installningar sparade',
        da: 'Indstillinger gemt',
        fi: 'Asetukset tallennettu',
        no: 'Innstillinger lagret',
        pl: 'Ustawienia zapisane',
        cs: 'Nastaveni ulozeno',
        sk: 'Nastavenia ulozene',
        tr: 'Ayarlar kaydedildi',
        ru: 'Nastroiki sohraneny',
        uk: 'Nalashtuvannia zberezheno',
        ja: 'Settings saved',
        ko: 'Settings saved',
        zh: 'Settings saved'
      },
      error: {
        en: 'Error',
        es: 'Error',
        fr: 'Erreur',
        de: 'Fehler',
        it: 'Errore',
        pt: 'Erro',
        nl: 'Fout',
        sv: 'Fel',
        da: 'Fejl',
        fi: 'Virhe',
        no: 'Feil',
        pl: 'Blad',
        cs: 'Chyba',
        sk: 'Chyba',
        tr: 'Hata',
        ru: 'Oshibka',
        uk: 'Pomylka',
        ja: 'Error',
        ko: 'Error',
        zh: 'Error'
      },
      username: {
        en: 'Username',
        es: 'Usuario',
        fr: 'Nom d utilisateur',
        de: 'Benutzername',
        it: 'Nome utente',
        pt: 'Nome de usuario'
      },
      password: {
        en: 'Password',
        es: 'Contrasena',
        fr: 'Mot de passe',
        de: 'Passwort',
        it: 'Password',
        pt: 'Senha'
      },
      save: {
        en: 'Save',
        es: 'Guardar',
        fr: 'Enregistrer',
        de: 'Speichern',
        it: 'Salva',
        pt: 'Salvar'
      }
    };

    const table = dict[key] || {};
    return table[lang] || table.en || fallback;
  }

  function prettifyKey(value) {
    const withSpaces = String(value || '')
      .replace(/^Label/, '')
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .replace(/[_-]+/g, ' ')
      .trim();
    if (!withSpaces) return '';
    return withSpaces.charAt(0).toUpperCase() + withSpaces.slice(1);
  }

  function resolveToken(token) {
    const map = {
      LabelUsername: localize('username', 'Username'),
      LabelPassword: localize('password', 'Password'),
      LabelSave: localize('save', 'Save')
    };

    if (map[token]) {
      return map[token];
    }

    return prettifyKey(token) || token;
  }

  function replaceLocalizedTokens(root) {
    const tokenRegex = /\$\{([^}]+)\}/g;
    const walker = document.createTreeWalker(root || document.body, NodeFilter.SHOW_TEXT);
    const textNodes = [];
    while (walker.nextNode()) {
      textNodes.push(walker.currentNode);
    }

    textNodes.forEach(function (node) {
      const text = node.nodeValue || '';
      if (!tokenRegex.test(text)) {
        tokenRegex.lastIndex = 0;
        return;
      }
      tokenRegex.lastIndex = 0;
      node.nodeValue = text.replace(tokenRegex, function (_, token) {
        return resolveToken(token);
      });
    });
  }

  function ensureFormLabels() {
    const fields = document.querySelectorAll('input, select, textarea');
    fields.forEach(function (field) {
      if (field.type === 'hidden' || field.type === 'checkbox' || field.type === 'radio') {
        return;
      }

      const explicitLabel = field.getAttribute('label') || field.getAttribute('aria-label');
      const inferred = explicitLabel || prettifyKey(field.id || field.name || '');
      if (!inferred) {
        return;
      }

      if (field.id && !document.querySelector('label[for="' + field.id + '"]')) {
        const label = document.createElement('label');
        label.setAttribute('for', field.id);
        label.className = 'mf-generated-label';
        label.textContent = inferred;
        field.parentNode && field.parentNode.insertBefore(label, field);
      }

      if (!field.getAttribute('placeholder')) {
        field.setAttribute('placeholder', inferred);
      }
    });
  }

  function hydrateEnhancedUi() {
    replaceLocalizedTokens(document.body);
    ensureFormLabels();
    enhanceCustomComponents();
    enhanceTabLinks();
  }

  function parseTabValue(urlValue) {
    try {
      const parsed = new URL(urlValue, serverBase);
      return parsed.searchParams.get('tab') || '';
    } catch (_) {
      const m = /(?:[?&])tab=([^&#]+)/i.exec(String(urlValue || ''));
      return m && m[1] ? decodeURIComponent(m[1]) : '';
    }
  }

  function currentTabValue() {
    try {
      return new URL(window.location.href).searchParams.get('tab') || '';
    } catch (_) {
      return '';
    }
  }

  function enhanceCustomComponents() {
    const customSelects = document.querySelectorAll('emby-select, [is="emby-select"], em-select');
    customSelects.forEach(function (component) {
      component.style.visibility = 'visible';
      component.style.opacity = '1';
      component.style.display = 'block';

      const labels = component.querySelectorAll('label, .label, [class*="Label"]');
      labels.forEach(function (label) {
        label.style.display = 'block';
        label.style.visibility = 'visible';
        label.style.opacity = '1';
        label.style.marginBottom = '6px';
      });

      const descriptions = component.querySelectorAll('[class*="description"], .desc');
      descriptions.forEach(function (desc) {
        desc.style.display = 'block';
        desc.style.visibility = 'visible';
        desc.style.opacity = '1';
        desc.style.marginTop = '4px';
      });

      const icons = component.querySelectorAll('.icon, [class*="Icon"]');
      icons.forEach(function (icon) {
        const parent = icon.parentNode;
        if (parent) {
          parent.style.display = 'flex';
          parent.style.alignItems = 'center';
          icon.style.marginRight = '8px';
          icon.style.display = 'inline-block';
        }
      });

      Array.from(component.childNodes).forEach(function (node) {
        if (node.nodeType === Node.TEXT_NODE && node.textContent.trim()) {
          const span = document.createElement('span');
          span.textContent = node.textContent;
          span.style.display = 'inline';
          node.parentNode.insertBefore(span, node);
          node.parentNode.removeChild(node);
        }
      });
    });

    const customInputs = document.querySelectorAll('emby-input, [is="emby-input"], em-input');
    customInputs.forEach(function (component) {
      component.style.visibility = 'visible';
      component.style.opacity = '1';
      component.style.display = 'block';

      const labels = component.querySelectorAll('label');
      labels.forEach(function (label) {
        label.style.display = 'block';
        label.style.visibility = 'visible';
      });
    });

    const checkboxGroups = document.querySelectorAll('emby-checkbox, [is="emby-checkbox"], em-checkbox');
    checkboxGroups.forEach(function (component) {
      component.style.display = 'flex';
      component.style.alignItems = 'center';
      component.style.visibility = 'visible';

      const labels = component.querySelectorAll('label');
      labels.forEach(function (label) {
        label.style.display = 'inline';
        label.style.marginLeft = '8px';
        label.style.visibility = 'visible';
      });
    });

    const allFieldDescriptions = document.querySelectorAll('[class*="FieldDescription"], [class*="field-description"], .hint, [class*="hint"]');
    allFieldDescriptions.forEach(function (desc) {
      desc.style.display = 'block';
      desc.style.visibility = 'visible';
      desc.style.opacity = '1';
    });
  }

  function enhanceTabLinks() {
    const currentTab = currentTabValue();
    const groups = Array.from(document.querySelectorAll('div, nav, section, p'));

    groups.forEach(function (container) {
      if (!container || container.classList.contains('mf-tab-row')) {
        return;
      }

      const links = Array.from(container.querySelectorAll(':scope > a[href]'));
      if (links.length < 2) {
        return;
      }

      const tabLinks = links.filter(function (a) {
        const href = (a.getAttribute('href') || '').toLowerCase();
        return href.indexOf('configurationpage') >= 0;
      });
      if (tabLinks.length < 2) {
        return;
      }

      container.classList.add('mf-tab-row');
      tabLinks.forEach(function (a) {
        const href = a.getAttribute('href') || '';
        const linkTab = parseTabValue(href);
        const hasActiveClass = /active|selected|is-active/i.test(a.className || '');
        const isActive = hasActiveClass || (currentTab && linkTab && currentTab === linkTab);

        a.classList.add('mf-tab-link');
        if (isActive) {
          a.classList.add('mf-tab-link-active');
        } else {
          a.classList.remove('mf-tab-link-active');
        }
      });
    });
  }

  function absoluteUrl(path) {
    if (!path) return serverBase;
    if (/^https?:/i.test(path)) return path;
    if (path.startsWith('/')) return serverBase.replace(/\/$/, '') + path;
    return serverBase.replace(/\/$/, '') + '/' + path;
  }

  function appendQuery(url, params) {
    if (!params || typeof params !== 'object') {
      return url;
    }

    const q = new URLSearchParams();
    Object.keys(params).forEach(function (k) {
      const v = params[k];
      if (v === null || v === undefined || v === '') {
        return;
      }

      if (Array.isArray(v)) {
        v.forEach(function (item) {
          if (item !== null && item !== undefined && item !== '') {
            q.append(k, String(item));
          }
        });
      } else {
        q.append(k, String(v));
      }
    });

    const queryString = q.toString();
    if (!queryString) {
      return url;
    }

    return url + (url.indexOf('?') >= 0 ? '&' : '?') + queryString;
  }

  function withAuthHeaders(headers) {
    const merged = Object.assign({}, headers || {});
    if (!merged['X-Emby-Token']) {
      merged['X-Emby-Token'] = token;
    }
    if (!merged['Authorization']) {
      merged['Authorization'] = 'MediaBrowser Token="' + token + '"';
    }
    return merged;
  }

  async function apiRequest(path, options) {
    const response = await fetch(absoluteUrl(path), {
      method: options.method || 'GET',
      headers: withAuthHeaders(Object.assign({
        'X-Emby-Token': token,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }, options.headers || {})),
      body: options.body
    });

    if (!response.ok) {
      throw response;
    }

    const contentType = response.headers.get('content-type') || '';
    if (contentType.indexOf('application/json') >= 0) {
      return await response.json();
    }

    return await response.text();
  }

  window.ApiClient = window.ApiClient || {};
  window.ApiClient.getUrl = function (path, params) {
    return appendQuery(absoluteUrl(path), params);
  };
  window.ApiClient.accessToken = function () {
    return token;
  };
  window.ApiClient.serverAddress = function () {
    return serverBase;
  };
  window.ApiClient.getCurrentUserId = function () {
    return currentUserId || '';
  };
  window.ApiClient.getJSON = function (url) {
    return fetch(absoluteUrl(url), {
      method: 'GET',
      headers: withAuthHeaders({ 'Accept': 'application/json' })
    }).then(function (r) {
      if (!r.ok) throw r;
      return r.json();
    });
  };
  window.ApiClient.getItems = function (userId, query) {
    return window.ApiClient.getJSON(window.ApiClient.getUrl('Users/' + userId + '/Items', query));
  };
  window.ApiClient.getUserViews = function (userId) {
    return window.ApiClient.getJSON(window.ApiClient.getUrl('Users/' + userId + '/Views'));
  };
  window.ApiClient.fetch = function (request) {
    const method = (request && (request.type || request.method)) || 'GET';
    return apiRequest(request.url, {
      method: method,
      headers: request.headers,
      body: request.data ? JSON.stringify(request.data) : undefined
    });
  };
  window.ApiClient.getPluginConfiguration = function (pluginId) {
    return apiRequest('/Plugins/' + pluginId + '/Configuration', { method: 'GET' });
  };
  window.ApiClient.updatePluginConfiguration = function (pluginId, config) {
    return apiRequest('/Plugins/' + pluginId + '/Configuration', {
      method: 'POST',
      body: JSON.stringify(config)
    });
  };
  window.ApiClient.ajax = function (request) {
    const method = (request && request.type) || 'GET';
    return fetch(absoluteUrl(request.url), {
      method: method,
      headers: withAuthHeaders(Object.assign({ 'X-Emby-Token': token }, request.headers || {})),
      body: request.data
    });
  };

  const nativeFetch = window.fetch.bind(window);
  window.fetch = function (input, init) {
    const requestInit = Object.assign({}, init || {});
    requestInit.headers = withAuthHeaders(requestInit.headers);
    return nativeFetch(input, requestInit);
  };

  window.Dashboard = window.Dashboard || {};
  window.Dashboard.getPluginUrl = function (name) {
    return 'configurationpage?name=' + encodeURIComponent(name || '');
  };
  window.Dashboard.getConfigurationResourceUrl = function (name) {
    return window.ApiClient.getUrl('web/ConfigurationPage', { name: name });
  };
  window.Dashboard.navigate = function (url) {
    if (!url) {
      return;
    }

    const urlStr = String(url);
    if (urlStr.toLowerCase().indexOf('configurationpage') >= 0) {
      const queryMatch = /configurationpage\?([^#]+)/i.exec(urlStr);
      const query = queryMatch && queryMatch[1] ? queryMatch[1] : '';
      if (query) {
        window.location.href = absoluteUrl('/web/ConfigurationPage?' + query);
        return;
      }

      const nameMatch = /(?:[?&#]|^)name=([^&#]+)/i.exec(urlStr);
      if (nameMatch && nameMatch[1]) {
        const name = decodeURIComponent(nameMatch[1]);
        window.location.href = window.ApiClient.getUrl('web/ConfigurationPage', { name: name });
        return;
      }
    }

    window.location.href = absoluteUrl(url);
  };
  window.Dashboard.showLoadingMsg = function () {};
  window.Dashboard.hideLoadingMsg = function () {};
  window.Dashboard.alert = function (opts) {
    const title = opts && opts.title ? opts.title + '\\n' : '';
    const message = opts && opts.message ? opts.message : localize('error', 'Error');
    window.alert(title + message);
  };
  window.Dashboard.processPluginConfigurationUpdateResult = function () {
    const savedText = localize('settingsSaved', 'Settings saved');

    const el = document.createElement('div');
    el.textContent = savedText;
    el.style.position = 'fixed';
    el.style.right = '16px';
    el.style.bottom = '16px';
    el.style.padding = '10px 12px';
    el.style.background = '#1f7a3f';
    el.style.color = '#fff';
    el.style.borderRadius = '8px';
    el.style.zIndex = '9999';
    document.body.appendChild(el);
    setTimeout(function () {
      if (el && el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }, 1800);
  };

  const style = document.createElement('style');
  style.textContent = `
    @import url('https://fonts.googleapis.com/icon?family=Material+Icons');

    .material-icons {
      font-family: 'Material Icons';
      font-weight: normal;
      font-style: normal;
      font-size: 1em;
      display: inline-block;
      line-height: 1;
      text-transform: none;
      letter-spacing: normal;
      white-space: nowrap;
      word-wrap: normal;
      direction: ltr;
      -webkit-font-feature-settings: 'liga';
      -webkit-font-smoothing: antialiased;
      vertical-align: middle;
    }

    .mf-tab-row {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 10px 0 14px;
      padding: 8px;
      border-radius: 12px;
      background: rgba(0, 0, 0, 0.06);
      border: 1px solid rgba(0, 0, 0, 0.1);
    }

    .mf-tab-link {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 40px;
      padding: 8px 14px;
      border-radius: 8px;
      border: 2px solid #cccccc;
      background: #ffffff;
      color: #1f2328 !important;
      text-decoration: none;
      font-weight: 600;
      line-height: 1.1;
      outline: 2px solid transparent;
      outline-offset: 2px;
      transition: all 0.2s ease;
      cursor: pointer;
    }

    .mf-tab-link:hover {
      background: #f0f0f0;
      color: #000000 !important;
      border-color: #999999;
      outline: 2px solid #cccccc;
      outline-offset: -2px;
    }

    .mf-tab-link-active {
      background: #007fbe !important;
      border: 2px solid #005a8f !important;
      color: #ffffff !important;
      box-shadow: 0 0 0 3px rgba(0, 127, 190, 0.2);
      outline: 2px solid #003d5c;
      outline-offset: -2px;
      font-weight: 700;
    }

    .mf-tab-link-active:hover {
      background: #0066a1 !important;
      border-color: #004080 !important;
    }

    html, body {
      margin: 0;
      padding: 0;
      line-height: 1.45;
      -webkit-text-size-adjust: 100%;
    }

    body {
      padding: 16px;
      box-sizing: border-box;
    }

    #configPage, .configPage {
      max-width: 980px;
      margin: 0 auto;
    }

    .content-primary {
      width: 100%;
    }

    .verticalSection,
    .inputContainer,
    .selectContainer,
    .checkboxContainer {
      margin-bottom: 12px;
    }

    .fieldDescription {
      margin-top: 4px;
      opacity: 0.9;
    }

    .mf-generated-label {
      display: block;
      margin-bottom: 6px;
      font-weight: 600;
      font-size: 0.95rem;
    }

    input[type="text"],
    input[type="password"],
    input[type="number"],
    input[type="email"],
    textarea,
    select {
      width: 100%;
      min-height: 40px;
      box-sizing: border-box;
      border-radius: 8px;
      border: 1px solid rgba(0, 0, 0, 0.35);
      padding: 8px 10px;
      font: inherit;
      background: #fff;
    }

    h1 {
      margin: 0 0 12px 0;
      font-size: 1.4rem;
    }

    h2 {
      margin: 18px 0 8px 0;
      font-size: 1.1rem;
    }

    .button-submit {
      margin-top: 12px;
      min-height: 42px;
    }

    emby-select,
    emby-input,
    [is="emby-select"],
    [is="emby-input"],
    em-select,
    em-input {
      display: block;
      width: 100%;
      margin-bottom: 12px;
    }

    emby-select label,
    emby-input label,
    [is="emby-select"] label,
    [is="emby-input"] label,
    em-select label,
    em-input label {
      display: block;
      margin-bottom: 6px;
      font-weight: 600;
      font-size: 0.95rem;
      color: inherit;
    }

    .fieldDescription,
    .description,
    [class*="description"],
    [class*="label"] {
      display: block !important;
      color: inherit !important;
      opacity: 1 !important;
      visibility: visible !important;
      margin-top: 4px;
    }

    emby-select .icon,
    emby-input .icon,
    [is="emby-select"] .icon,
    [is="emby-input"] .icon,
    em-select .icon,
    em-input .icon {
      display: inline-block;
      margin-right: 8px;
      font-size: 1.2em;
      vertical-align: middle;
    }

    emby-select [class*="text"],
    emby-input [class*="text"],
    [is="emby-select"] [class*="text"],
    [is="emby-input"] [class*="text"],
    em-select [class*="text"],
    em-input [class*="text"] {
      display: inline-block;
      color: inherit;
      visibility: visible;
    }

    emby-select[multiple],
    select[multiple],
    [is="emby-select"][multiple] {
      min-height: 100px;
    }

    emby-select option,
    [is="emby-select"] option,
    em-select option {
      display: block !important;
      visibility: visible !important;
      color: #1f2328;
    }

    paper-button,
    button[is="paper-button"],
    [is="paper-button"],
    button {
      visibility: visible;
      display: inline-block;
    }

    emby-checkbox,
    [is="emby-checkbox"],
    em-checkbox {
      display: flex;
      align-items: center;
      margin-bottom: 10px;
    }

    emby-checkbox label,
    [is="emby-checkbox"] label,
    em-checkbox label {
      display: inline;
      margin-left: 8px;
      font-weight: normal;
    }

    body * {
      visibility: visible;
      opacity: 1;
      color: inherit;
    }

    .mf-field-group,
    .field-group,
    [class*="fieldGroup"],
    [class*="FieldGroup"] {
      display: block;
      margin-bottom: 16px;
      padding: 8px 0;
    }

    @media (max-width: 640px) {
      body {
        padding: 12px;
      }

      emby-select,
      emby-input,
      [is="emby-select"],
      [is="emby-input"],
      em-select,
      em-input {
        width: 100%;
      }

      emby-select[multiple],
      select[multiple],
      [is="emby-select"][multiple] {
        min-height: 80px;
      }
    }
  `;
  document.head.appendChild(style);
  hydrateEnhancedUi();

  window.addEventListener('load', function () {
    const pages = document.querySelectorAll('.configPage, .pluginConfigurationPage, [data-role="page"]');
    if (pages.length > 0) {
      pages.forEach(function (page) {
        page.dispatchEvent(new Event('pageshow', { bubbles: true, cancelable: false }));
      });
    } else {
      document.dispatchEvent(new Event('pageshow', { bubbles: true, cancelable: false }));
    }

    hydrateEnhancedUi();
    setTimeout(hydrateEnhancedUi, 250);
    setTimeout(hydrateEnhancedUi, 500);
    setTimeout(hydrateEnhancedUi, 1000);
  });

  if (typeof MutationObserver !== 'undefined') {
    let hydrateScheduled = false;
    const observer = new MutationObserver(function () {
      if (hydrateScheduled) {
        return;
      }

      hydrateScheduled = true;
      requestAnimationFrame(function () {
        hydrateScheduled = false;
        hydrateEnhancedUi();
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['class', 'style', 'hidden']
    });
  }
})();
</script>
''';

    final injectedShim = shim
        .replaceAll('__SERVER_BASE__', base)
      .replaceAll('__TOKEN__', token)
      .replaceAll('__USER_ID__', userId);

    if (originalHtml.contains('</body>')) {
      return originalHtml.replaceFirst('</body>', '$injectedShim</body>');
    }

    return '$originalHtml$injectedShim';
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(_addressController.text.trim()) ?? _currentConfigurationPageUri;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsEmbeddedWebView) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_browser, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Embedded browser is not available on this platform.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Browser'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Open externally',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 && _progress < 100 ? _progress / 100 : null,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 620;

                final navButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      visualDensity: VisualDensity.compact,
                      onPressed: _canGoBack
                          ? () async {
                              await controller.goBack();
                              await _refreshNavigationState();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    IconButton(
                      tooltip: 'Forward',
                      visualDensity: VisualDensity.compact,
                      onPressed: _canGoForward
                          ? () async {
                              await controller.goForward();
                              await _refreshNavigationState();
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      visualDensity: VisualDensity.compact,
                      onPressed: _loadPluginConfigHtml,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );

                final addressField = TextField(
                  controller: _addressController,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _goToAddress(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Address',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.language, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          navButtons,
                          const Spacer(),
                          IconButton(
                            tooltip: 'Go',
                            visualDensity: VisualDensity.compact,
                            onPressed: _goToAddress,
                            icon: const Icon(Icons.arrow_right_alt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      addressField,
                    ],
                  );
                }

                return Row(
                  children: [
                    navButtons,
                    const SizedBox(width: 8),
                    Expanded(child: addressField),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Go',
                      onPressed: _goToAddress,
                      icon: const Icon(Icons.arrow_right_alt),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}
