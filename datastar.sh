#!/usr/bin/env bash
set -euo pipefail

# Datastar + Bulma + PHTML + FastRoute + Diactoros (SAPI dev server)
#
# Usage:
#   ./datastar_sapi.sh my-app
#
# Then:
#   cd my-app
#   composer install
#   composer run dev:sapi

PROJECT_NAME="${1:-warehouse-star}"
PHP_MIN_VERSION="8.3.0"

# Pin these for reproducible learning.
DATASTAR_TAG="1.0.0-RC.7"
BULMA_VERSION="1.0.2"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_php_ext_or_die() {
  php -r "exit(extension_loaded('$1') ? 0 : 1);" >/dev/null 2>&1 || {
    echo "Missing required PHP extension: $1" >&2
    exit 1
  }
}

require_cmd php
require_cmd composer
require_cmd sqlite3

php -r "exit(version_compare(PHP_VERSION, '$PHP_MIN_VERSION', '>=') ? 0 : 1);" || {
  echo "PHP $PHP_MIN_VERSION+ required. Found: $(php -r 'echo PHP_VERSION;')" >&2
  exit 1
}

require_php_ext_or_die json
require_php_ext_or_die pdo
require_php_ext_or_die pdo_sqlite

if [[ -e "$PROJECT_NAME" ]]; then
  echo "Directory already exists: $PROJECT_NAME" >&2
  exit 1
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

mkdir -p   public/assets   src/Http   src/Security   templates/inventory   templates/layout   templates/partials   var

cat > composer.json <<JSON
{
  "name": "krish/$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//')",
  "description": "Datastar + Bulma + phtml starter (SAPI-first, fragment-driven).",
  "type": "project",
  "license": "MIT",
  "require": {
    "php": "^8.3",
    "ext-json": "*",
    "ext-pdo": "*",
    "ext-pdo_sqlite": "*",
    "laminas/laminas-diactoros": "^3.0",
    "laminas/laminas-escaper": "^2.18",
    "laminas/laminas-httphandlerrunner": "^2.13.0",
    "laminas/laminas-view": "^2.44.0",
    "nikic/fast-route": "^v1.3"
  },
  "autoload": {
    "psr-4": {
      "App\\": "src/"
    }
  },
  "scripts": {
    "dev:sapi": "php -S 127.0.0.1:8080 -t public public/index.php"
  },
  "config": {
    "sort-packages": true,
    "allow-plugins": {
      "laminas/laminas-dependency-plugin": true
    }
  }
}
JSON

cat > .gitignore <<'TXT'
/vendor/
/var/*.db
/var/*.db-*
/var/*.sqlite
/var/cache/*
/.idea/
/.DS_Store
TXT

cat > README.md <<'MD'
# Warehouse Star (Datastar + Bulma + PHTML + Laminas View)

This is a tiny, **SAPI-first** starter focused on learning a clean pattern:

- **PHTML server rendering** with `laminas/laminas-view`
- **Bulma** for styling (no build step)
- **Datastar request/response** for small, targeted HTML updates (no SSE)

The key idea: **the server always returns HTML** (full pages or fragments), and Datastar
morphs fragments into stable DOM targets by **ID**.

## Run
```bash
composer install
composer run dev:sapi
```

Open: http://127.0.0.1:8080

## What to look for (learning map)

### 1) Stable DOM targets
These IDs are the contract between server and browser:

- `#inventory-grid` (table `<tbody>`)
- `#row-<id>` (single `<tr>`)
- `#modal-container` (modal mount point)
- `#toasts` (toast mount point)

### 2) Progressive enhancement
Everything works without JS:

- Search uses a normal `<form method="get" action="/">`
- Edit is a normal `<a href="/inventory/edit/:id">`
- Save is a normal `<form method="post">`

With Datastar enabled, we intercept and do `@get(...)` / `@post(...)` so the server can
return **just the fragment(s)**.

### 3) Server decides: full page vs fragments
We check a Datastar request header and either:

- render a full page (`layout/master + inventory/index`), or
- render just a partial like `inventory/_grid` / `inventory/_modal` / `partials/toasts`.

## Routes
- `GET /` full page (SSR)
- `GET /inventory/search` returns `#inventory-grid` when Datastar initiates it
- `GET /inventory/edit/{id}` returns `#modal-container` when Datastar initiates it
- `POST /inventory/save/{id}` returns `#row-{id}` + empty modal + `#toasts` when Datastar initiates it
- `POST /inventory/bulk/zero` returns `#inventory-grid` + `#toasts` when Datastar initiates it

SQLite DB: `var/app.db`
MD

cat > public/assets/app.css <<'CSS'
:root {
  --toast-width: 380px;
}

.toast-container {
  position: fixed;
  top: 1rem;
  right: 1rem;
  width: min(var(--toast-width), calc(100vw - 2rem));
  z-index: 60;
}

.toast-container .notification + .notification {
  margin-top: 0.75rem;
}

/* Datastar cloak pattern */
[data-cloak] {
  display: none !important;
}
CSS

cat > src/View.php <<'PHP'
<?php

declare(strict_types=1);

namespace App;

use Laminas\View\Renderer\PhpRenderer;
use Laminas\View\Resolver\TemplatePathStack;

final class View
{
    public static function renderer(string $templatesPath): PhpRenderer
    {
        $renderer = new PhpRenderer();
        $resolver = new TemplatePathStack(['script_paths' => [$templatesPath]]);
        $renderer->setResolver($resolver);

        return $renderer;
    }

    /**
     * Render a full HTML page using the master layout.
     *
     * @param array<string, mixed> $params
     */
    public static function page(PhpRenderer $renderer, string $template, array $params = []): string
    {
        $content = $renderer->render($template, $params);

        // Keep these as data (not strings) so layout can render partials.
        $toasts = is_array($params['toasts'] ?? null) ? $params['toasts'] : [];
        $modalHtml = is_string($params['modalHtml'] ?? null) ? (string) $params['modalHtml'] : '';

        return $renderer->render('layout/master', [
            'content' => $content,
            'toasts' => $toasts,
            // If empty, layout renders an empty container with the correct ID.
            'modalHtml' => $modalHtml,
        ]);
    }
}
PHP

cat > src/Http/Datastar.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Http;

use Laminas\Diactoros\Response\HtmlResponse;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final class Datastar
{
    /**
     * Datastar adds a request header so the server can return fragments instead of full pages.
     *
     * We treat any truthy value as "yes".
     */
    public static function isDatastarRequest(ServerRequestInterface $request): bool
    {
        $v = strtolower(trim(
            $request->getHeaderLine('Datastar-Request')
            ?: $request->getHeaderLine('X-Datastar-Request')
        ));

        return $v === 'true' || $v === '1' || $v === 'yes';
    }

    /**
     * Datastar GET requests send signals as a query param (JSON).
     *
     * This app expects `?datastar=<json>`.
     *
     * @return array<string, mixed>
     */
    public static function readGetSignals(ServerRequestInterface $request): array
    {
        $qp = $request->getQueryParams();
        $raw = $qp['datastar'] ?? null;

        if (!is_string($raw) || $raw === '') {
            return [];
        }

        $decoded = json_decode($raw, true);

        return is_array($decoded) ? $decoded : [];
    }

    public static function html(string $html, int $status = 200): ResponseInterface
    {
        // HtmlResponse already sets Content-Type to text/html with a charset.
        return new HtmlResponse($html, $status);
    }
}
PHP

cat > src/Http/RequestInputs.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Http;

use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Message\StreamInterface;

final class RequestInputs
{
    /**
     * Parse request body for common non-file requests.
     *
     * Supports:
     * - application/x-www-form-urlencoded
     * - application/json
     *
     * @return array<string, mixed>
     */
    public static function body(ServerRequestInterface $request): array
    {
        $method = strtoupper($request->getMethod());
        if ($method === 'GET' || $method === 'HEAD') {
            return [];
        }

        $parsed = $request->getParsedBody();
        if (is_array($parsed)) {
            /** @var array<string, mixed> */
            return $parsed;
        }

        $contentType = strtolower($request->getHeaderLine('Content-Type'));
        $raw = self::readAll($request->getBody());

        if ($raw === '') {
            return [];
        }

        if (str_contains($contentType, 'application/json')) {
            $decoded = json_decode($raw, true);
            return is_array($decoded) ? $decoded : [];
        }

        // Default HTML forms (no files) are urlencoded
        if (str_contains($contentType, 'application/x-www-form-urlencoded')) {
            $form = [];
            parse_str($raw, $form);
            return is_array($form) ? $form : [];
        }

        // Best-effort fallback: try parse_str
        $fallback = [];
        parse_str($raw, $fallback);
        return is_array($fallback) ? $fallback : [];
    }

    private static function readAll(StreamInterface $stream): string
    {
        if ($stream->isSeekable()) {
            $stream->rewind();
        }

        return $stream->getContents();
    }
}
PHP

cat > src/Security/Csrf.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Security;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final class Csrf
{
    private const COOKIE = 'csrf_token';
    private const FIELD  = 'csrf_token';

    public static function token(ServerRequestInterface $request): string
    {
        $cookies = $request->getCookieParams();
        $token = $cookies[self::COOKIE] ?? '';

        if (is_string($token) && self::looksValid($token)) {
            return $token;
        }

        return self::newToken();
    }

    /**
     * @param array<string, mixed> $body
     */
    public static function validate(ServerRequestInterface $request, array $body): bool
    {
        $cookies = $request->getCookieParams();
        $cookieToken = (string) ($cookies[self::COOKIE] ?? '');
        $bodyToken = (string) ($body[self::FIELD] ?? '');

        if (!self::looksValid($cookieToken) || !self::looksValid($bodyToken)) {
            return false;
        }

        return hash_equals($cookieToken, $bodyToken);
    }

    public static function ensureCookie(ServerRequestInterface $request, ResponseInterface $response, string $token): ResponseInterface
    {
        $cookies = $request->getCookieParams();
        $existing = $cookies[self::COOKIE] ?? null;

        if (is_string($existing) && $existing === $token) {
            return $response;
        }

        $secure = strtolower($request->getUri()->getScheme()) === 'https';

        $parts = [
            self::COOKIE . '=' . rawurlencode($token),
            'Path=/',
            'SameSite=Lax',
            'HttpOnly',
        ];

        if ($secure) {
            $parts[] = 'Secure';
        }

        return $response->withAddedHeader('Set-Cookie', implode('; ', $parts));
    }

    public static function fieldName(): string
    {
        return self::FIELD;
    }

    private static function newToken(): string
    {
        // URL-safe base64 without padding.
        return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
    }

    private static function looksValid(string $token): bool
    {
        $len = strlen($token);
        return $len >= 32 && $len <= 128;
    }
}
PHP

cat > src/InventoryRepository.php <<'PHP'
<?php

declare(strict_types=1);

namespace App;

use PDO;

final class InventoryRepository
{
    public function __construct(private PDO $pdo)
    {
    }

    /**
     * @return array<int, array{id:int, sku:string, name:string, stock:int}>
     */
    public function search(string $query): array
    {
        $query = trim($query);

        if ($query === '') {
            $stmt = $this->pdo->query(
                "SELECT id, sku, name, stock
                 FROM products
                 ORDER BY id ASC
                 LIMIT 50"
            );

            /** @var array<int, array{id:int, sku:string, name:string, stock:int}> */
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        $stmt = $this->pdo->prepare(
            "SELECT id, sku, name, stock
             FROM products
             WHERE sku LIKE :q OR name LIKE :q
             ORDER BY id ASC
             LIMIT 50"
        );

        $like = '%' . $query . '%';
        $stmt->execute(['q' => $like]);

        /** @var array<int, array{id:int, sku:string, name:string, stock:int}> */
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * @return array{id:int, sku:string, name:string, stock:int}|null
     */
    public function get(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            "SELECT id, sku, name, stock
             FROM products
             WHERE id = :id"
        );
        $stmt->execute(['id' => $id]);

        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }

    public function setStock(int $id, int $stock): void
    {
        $stmt = $this->pdo->prepare(
            "UPDATE products SET stock = :stock WHERE id = :id"
        );
        $stmt->execute(['id' => $id, 'stock' => $stock]);
    }

    /**
     * @param array<int, int> $ids
     */
    public function bulkSetStock(array $ids, int $stock): int
    {
        $ids = array_values(array_unique(array_filter($ids, static fn ($v) => $v > 0)));

        if ($ids === []) {
            return 0;
        }

        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $sql = "UPDATE products SET stock = ? WHERE id IN ($placeholders)";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_merge([$stock], $ids));

        return $stmt->rowCount();
    }
}
PHP

cat > src/AppKernel.php <<'PHP'
<?php

declare(strict_types=1);

namespace App;

use App\Http\Datastar;
use App\Http\RequestInputs;
use App\Security\Csrf;
use FastRoute\Dispatcher;
use FastRoute\RouteCollector;
use Laminas\Diactoros\Response;
use Laminas\Diactoros\Response\HtmlResponse;
use Laminas\View\Renderer\PhpRenderer;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final class AppKernel
{
    private Dispatcher $dispatcher;

    public function __construct(
        private InventoryRepository $repo,
        private PhpRenderer $view
    ) {
        $this->dispatcher = \FastRoute\simpleDispatcher(function (RouteCollector $r): void {
            $r->addRoute('GET', '/', 'inventory.page');
            $r->addRoute('GET', '/inventory/search', 'inventory.search');
            $r->addRoute('GET', '/inventory/edit/{id:\d+}', 'inventory.edit');
            $r->addRoute('POST', '/inventory/save/{id:\d+}', 'inventory.save');
            $r->addRoute('POST', '/inventory/bulk/zero', 'inventory.bulk.zero');
        });
    }

    public function handle(ServerRequestInterface $request): ResponseInterface
    {
        $path = $request->getUri()->getPath();
        $routeInfo = $this->dispatcher->dispatch($request->getMethod(), $path);

        switch ($routeInfo[0]) {
            case Dispatcher::NOT_FOUND:
                return new HtmlResponse('<h1>404 Not Found</h1>', 404);

            case Dispatcher::METHOD_NOT_ALLOWED:
                return new HtmlResponse('<h1>405 Method Not Allowed</h1>', 405);

            case Dispatcher::FOUND:
                $handler = $routeInfo[1];
                /** @var array<string, string> $vars */
                $vars = $routeInfo[2];

                return match ($handler) {
                    'inventory.page' => $this->inventoryPage($request),
                    'inventory.search' => $this->inventorySearch($request),
                    'inventory.edit' => $this->inventoryEdit($request, (int) ($vars['id'] ?? '0')),
                    'inventory.save' => $this->inventorySave($request, (int) ($vars['id'] ?? '0')),
                    'inventory.bulk.zero' => $this->inventoryBulkZero($request),
                    default => new Response('php://memory', 500),
                };
        }

        return new Response('php://memory', 500);
    }

    private function inventoryPage(ServerRequestInterface $request, array $toasts = [], string $modalHtml = ''): ResponseInterface
    {
        $q = (string) ($request->getQueryParams()['q'] ?? '');
        $products = $this->repo->search($q);

        $csrf = Csrf::token($request);

        $html = View::page($this->view, 'inventory/index', [
            'products' => $products,
            'query' => $q,
            'csrfToken' => $csrf,
            'toasts' => $toasts,
            'modalHtml' => $modalHtml,
        ]);

        $resp = Datastar::html($html, 200);
        return Csrf::ensureCookie($request, $resp, $csrf);
    }

    private function inventorySearch(ServerRequestInterface $request): ResponseInterface
    {
        // Prefer Datastar signals if present; fall back to regular query param q.
        $signals = Datastar::readGetSignals($request);
        $q = (string) ($signals['query'] ?? ($request->getQueryParams()['q'] ?? ''));

        $products = $this->repo->search($q);
        $gridHtml = $this->view->render('inventory/_grid', [
            'products' => $products,
        ]);

        if (Datastar::isDatastarRequest($request)) {
            return Datastar::html($gridHtml, 200);
        }

        // Non-Datastar: render a full page showing results.
        return $this->inventoryPage($request);
    }

    private function inventoryEdit(ServerRequestInterface $request, int $id): ResponseInterface
    {
        $product = $this->repo->get($id);
        $csrf = Csrf::token($request);

        if ($product === null) {
            $toasts = [['type' => 'danger', 'message' => 'Product not found.']];
            $toastsHtml = $this->view->render('partials/toasts', ['toasts' => $toasts]);

            $resp = Datastar::isDatastarRequest($request)
                ? Datastar::html($toastsHtml, 404)
                : $this->inventoryPage($request, $toasts);

            return Csrf::ensureCookie($request, $resp, $csrf);
        }

        $modalHtml = $this->view->render('inventory/_modal', [
            'product' => $product,
            'errors' => [],
            'submittedStock' => null,
            'csrfToken' => $csrf,
        ]);

        if (Datastar::isDatastarRequest($request)) {
            $resp = Datastar::html($modalHtml, 200);
            return Csrf::ensureCookie($request, $resp, $csrf);
        }

        // Non-Datastar: show full page with modal open.
        return $this->inventoryPage($request, [], $modalHtml);
    }

    private function inventorySave(ServerRequestInterface $request, int $id): ResponseInterface
    {
        $product = $this->repo->get($id);
        $body = RequestInputs::body($request);
        $csrf = Csrf::token($request);

        if ($product === null) {
            $toasts = [['type' => 'danger', 'message' => 'Product not found.']];
            return $this->finishSaveOrBulk($request, $toasts, null, null);
        }

        if (!Csrf::validate($request, $body)) {
            $toasts = [['type' => 'danger', 'message' => 'CSRF validation failed. Refresh and try again.']];
            return $this->finishSaveOrBulk($request, $toasts, $product, [
                'csrf' => 'Invalid CSRF token.',
            ], $body['stock'] ?? null);
        }

        $rawStock = $body['stock'] ?? null;

        $errors = [];
        $stock = null;

        if (is_int($rawStock)) {
            $stock = $rawStock;
        } elseif (is_string($rawStock) && $rawStock !== '') {
            $validated = filter_var($rawStock, FILTER_VALIDATE_INT);
            if ($validated !== false) {
                $stock = (int) $validated;
            }
        }

        if ($stock === null) {
            $errors['stock'] = 'Stock must be an integer.';
        } elseif ($stock < 0) {
            $errors['stock'] = 'Stock cannot be negative.';
        } elseif ($stock > 1_000_000) {
            $errors['stock'] = 'Stock is unrealistically high.';
        }

        if ($errors !== []) {
            return $this->finishSaveOrBulk($request, [], $product, $errors, $rawStock);
        }

        $this->repo->setStock($id, $stock);
        $updated = $this->repo->get($id);

        if ($updated === null) {
            $toasts = [['type' => 'danger', 'message' => 'Unexpected error reloading product.']];
            return $this->finishSaveOrBulk($request, $toasts, null, null);
        }

        $toasts = [['type' => 'success', 'message' => "Saved {$updated['sku']}." ]];

        // Datastar: patch the row, close the modal, and patch toasts.
        if (Datastar::isDatastarRequest($request)) {
            $row = $this->view->render('inventory/_row', ['product' => $updated]);
            $modalEmpty = $this->view->render('partials/modal_empty');
            $toastsHtml = $this->view->render('partials/toasts', ['toasts' => $toasts]);

            $resp = Datastar::html($row . $modalEmpty . $toastsHtml, 200);
            return Csrf::ensureCookie($request, $resp, $csrf);
        }

        // Non-Datastar: return full page with toast (no PRG in this demo).
        return $this->inventoryPage($request, $toasts);
    }

    private function inventoryBulkZero(ServerRequestInterface $request): ResponseInterface
    {
        $body = RequestInputs::body($request);
        $csrf = Csrf::token($request);

        $toasts = [];

        if (!Csrf::validate($request, $body)) {
            $toasts[] = ['type' => 'danger', 'message' => 'CSRF validation failed. Refresh and try again.'];
            return $this->finishBulk($request, $toasts);
        }

        $rawIds = $body['ids'] ?? [];
        $ids = [];

        if (is_array($rawIds)) {
            foreach ($rawIds as $v) {
                if (is_int($v)) {
                    $ids[] = $v;
                    continue;
                }
                if (is_string($v)) {
                    $validated = filter_var($v, FILTER_VALIDATE_INT);
                    if ($validated !== false) {
                        $ids[] = (int) $validated;
                    }
                }
            }
        }

        if ($ids === []) {
            $toasts[] = ['type' => 'warning', 'message' => 'Select at least one product.'];
        } else {
            $count = $this->repo->bulkSetStock($ids, 0);
            $toasts[] = ['type' => 'success', 'message' => "Set stock=0 for {$count} product(s)." ];
        }

        return $this->finishBulk($request, $toasts);
    }

    private function finishBulk(ServerRequestInterface $request, array $toasts): ResponseInterface
    {
        $q = '';
        $body = RequestInputs::body($request);
        if (isset($body['q']) && is_string($body['q'])) {
            $q = $body['q'];
        }

        $products = $this->repo->search($q);
        $gridHtml = $this->view->render('inventory/_grid', ['products' => $products]);
        $toastsHtml = $this->view->render('partials/toasts', ['toasts' => $toasts]);

        $csrf = Csrf::token($request);

        if (Datastar::isDatastarRequest($request)) {
            $resp = Datastar::html($gridHtml . $toastsHtml, 200);
            return Csrf::ensureCookie($request, $resp, $csrf);
        }

        return $this->inventoryPage($request, $toasts);
    }

    private function finishSaveOrBulk(
        ServerRequestInterface $request,
        array $toasts,
        ?array $product,
        ?array $errors,
        mixed $submittedStock = null
    ): ResponseInterface {
        $csrf = Csrf::token($request);

        if ($product !== null && $errors !== null) {
            $modalHtml = $this->view->render('inventory/_modal', [
                'product' => $product,
                'errors' => $errors,
                'submittedStock' => $submittedStock,
                'csrfToken' => $csrf,
            ]);

            if (Datastar::isDatastarRequest($request)) {
                $toastsHtml = $toasts !== [] ? $this->view->render('partials/toasts', ['toasts' => $toasts]) : '';
                $resp = Datastar::html($modalHtml . $toastsHtml, 422);
                return Csrf::ensureCookie($request, $resp, $csrf);
            }

            return $this->inventoryPage($request, $toasts, $modalHtml);
        }

        $toastsHtml = $this->view->render('partials/toasts', ['toasts' => $toasts]);

        if (Datastar::isDatastarRequest($request)) {
            $resp = Datastar::html($toastsHtml, 400);
            return Csrf::ensureCookie($request, $resp, $csrf);
        }

        return $this->inventoryPage($request, $toasts);
    }
}
PHP

cat > public/index.php <<'PHP'
<?php

declare(strict_types=1);

use App\AppKernel;
use App\InventoryRepository;
use App\View;
use Laminas\Diactoros\ServerRequestFactory;
use Laminas\HttpHandlerRunner\Emitter\SapiEmitter;

require __DIR__ . '/../vendor/autoload.php';

// Built-in server static file passthrough
if (PHP_SAPI === 'cli-server') {
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    $file = __DIR__ . $path;
    if (is_string($path) && is_file($file)) {
        return false;
    }
}

$pdo = new PDO('sqlite:' . __DIR__ . '/../var/app.db', null, null, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$repo = new InventoryRepository($pdo);
$renderer = View::renderer(__DIR__ . '/../templates');

$app = new AppKernel($repo, $renderer);

$request = ServerRequestFactory::fromGlobals();
$response = $app->handle($request);

(new SapiEmitter())->emit($response);
PHP

cat > templates/layout/master.phtml <<PHTML
<?php
/** @var string \$content */
/** @var array<int, array{type: string, message: string}> \$toasts */
/** @var string \$modalHtml */

\$toasts = is_array(\$toasts ?? null) ? \$toasts : [];
\$modalHtml = is_string(\$modalHtml ?? null) ? (string) \$modalHtml : '';
?>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Warehouse Star</title>

    <!-- Bulma (CDN, no build step) -->
    <link
      rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/bulma@${BULMA_VERSION}/css/bulma.min.css"
    />
    <link rel="stylesheet" href="/assets/app.css" />

    <!-- Datastar (request/response mode in this demo; no SSE) -->
    <script
      type="module"
      src="https://cdn.jsdelivr.net/gh/starfederation/datastar@${DATASTAR_TAG}/bundles/datastar.js"
    ></script>
  </head>

  <body>
    <section class="section">
      <?= \$content ?>
    </section>

    <?= \$this->render('partials/toasts', ['toasts' => \$toasts]) ?>

    <?php if (\$modalHtml !== ''): ?>
      <?= \$modalHtml ?>
    <?php else: ?>
      <?= \$this->render('partials/modal_empty') ?>
    <?php endif; ?>
  </body>
</html>
PHTML

cat > templates/partials/modal_empty.phtml <<'PHTML'
<div id="modal-container"></div>
PHTML

cat > templates/partials/toasts.phtml <<'PHTML'
<?php
/**
 * @var array<int, array{type: string, message: string}> $toasts
 */
$toasts = is_array($toasts ?? null) ? $toasts : [];
?>
<div id="toasts" class="toast-container" aria-live="polite" aria-atomic="true">
  <?php foreach ($toasts as $toast): ?>
    <?php
      $type = (string) ($toast['type'] ?? 'info');
      $message = (string) ($toast['message'] ?? '');
      $bulma = match ($type) {
        'success' => 'is-success',
        'warning' => 'is-warning',
        'danger'  => 'is-danger',
        default   => 'is-info',
      };
    ?>
    <div class="notification <?= $bulma ?>">
      <button
        class="delete"
        type="button"
        data-on:click="evt.target.closest('.notification').remove()"
        aria-label="Dismiss notification"
      ></button>
      <?= $this->escapeHtml($message) ?>
    </div>
  <?php endforeach; ?>
</div>
PHTML

cat > templates/inventory/index.phtml <<'PHTML'
<?php
/**
 * @var array<int, array{id:int, sku:string, name:string, stock:int}> $products
 * @var string $query
 * @var string $csrfToken
 */
$products = is_array($products ?? null) ? $products : [];
$query = (string) ($query ?? '');
$csrfToken = (string) ($csrfToken ?? '');

$signalsJson = json_encode(
  ['query' => $query, 'selectedIds' => []],
  JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
);
?>
<div
  class="container"
  data-cloak
  data-init="el.removeAttribute('data-cloak')"
  data-signals='<?= $this->escapeHtmlAttr((string) $signalsJson) ?>'
>
  <div class="level">
    <div class="level-left">
      <div>
        <h1 class="title is-3">Warehouse Star</h1>
        <p class="subtitle is-6">
          Datastar + Bulma + phtml (request/response).
        </p>
      </div>
    </div>

    <div class="level-right">
      <div class="buttons">
        <!-- Progressive enhancement: this is a real link (no JS: it just navigates to /). -->
        <a
          class="button is-light"
          href="/"
          style="<?= $query === '' ? 'display: none' : '' ?>"
          data-show="$query !== ''"
          data-on:click="evt.preventDefault(); $query = ''; $selectedIds = []; @get('/inventory/search', {filterSignals: {include: /^query$/}})"
        >
          Clear
        </a>

        <button
          class="button is-danger"
          type="submit"
          form="bulk-form"
          data-indicator="bulkBusy"
          data-class:is-loading="$bulkBusy"
          data-attr:disabled="$bulkBusy || $selectedIds.length === 0"
        >
          Bulk: set stock to 0
          <span class="tag is-light ml-2" data-text="$selectedIds.length">0</span>
        </button>
      </div>
    </div>
  </div>

  <div class="box">
    <form method="get" action="/" class="mb-3">
      <div class="field">
        <label class="label" for="search">Search</label>
        <div class="control" data-indicator="searching" data-class:is-loading="$searching">
          <input
            id="search"
            class="input"
            type="search"
            name="q"
            value="<?= $this->escapeHtmlAttr($query) ?>"
            placeholder="Search SKU or name…"
            autocomplete="off"
            data-bind="query"
            data-on:input__debounce.250ms="@get('/inventory/search', {filterSignals: {include: /^query$/}})"
          />
        </div>
        <p class="help">
          Type to search (Datastar patches just the table body). Press Enter for non-JS fallback.
        </p>
      </div>
    </form>

    <form
      id="bulk-form"
      method="post"
      action="/inventory/bulk/zero"
      data-on:submit="@post(el.action, {contentType: 'form'}); $selectedIds = []"
    >
      <input
        type="hidden"
        name="<?= $this->escapeHtmlAttr(\App\Security\Csrf::fieldName()) ?>"
        value="<?= $this->escapeHtmlAttr($csrfToken) ?>"
      />
      <input
        type="hidden"
        name="q"
        value="<?= $this->escapeHtmlAttr($query) ?>"
        data-bind="query"
      />

      <div class="table-container">
        <table class="table is-fullwidth is-striped is-hoverable">
          <thead>
            <tr>
              <th style="width: 3.25rem;"></th>
              <th>SKU</th>
              <th>Name</th>
              <th style="width: 7rem;">Stock</th>
              <th style="width: 9rem;">Actions</th>
            </tr>
          </thead>

          <?= $this->render('inventory/_grid', ['products' => $products]) ?>
        </table>
      </div>
    </form>

    <details class="mt-4">
      <summary class="has-text-grey is-size-7">Debug: signals</summary>
      <pre class="is-size-7 has-text-grey" data-json-signals__terse="{include: /^query$|^selectedIds$/}"></pre>
    </details>
  </div>
</div>
PHTML

cat > templates/inventory/_grid.phtml <<'PHTML'
<?php
/**
 * @var array<int, array{id:int, sku:string, name:string, stock:int}> $products
 */
$products = is_array($products ?? null) ? $products : [];
?>
<tbody id="inventory-grid">
  <?php foreach ($products as $product): ?>
    <?= $this->render('inventory/_row', ['product' => $product]) ?>
  <?php endforeach; ?>

  <?php if ($products === []): ?>
    <tr>
      <td colspan="5" class="has-text-grey">
        No results.
      </td>
    </tr>
  <?php endif; ?>
</tbody>
PHTML

cat > templates/inventory/_row.phtml <<'PHTML'
<?php
/**
 * @var array{id:int, sku:string, name:string, stock:int} $product
 */
$id = (int) ($product['id'] ?? 0);
$sku = (string) ($product['sku'] ?? '');
$name = (string) ($product['name'] ?? '');
$stock = (int) ($product['stock'] ?? 0);
?>
<tr id="row-<?= $id ?>">
  <td>
    <label class="checkbox">
      <input
        type="checkbox"
        name="ids[]"
        value="<?= $id ?>"
        data-bind="selectedIds"
      />
    </label>
  </td>

  <td><code><?= $this->escapeHtml($sku) ?></code></td>
  <td><?= $this->escapeHtml($name) ?></td>
  <td><?= $stock ?></td>

  <td>
    <!-- Progressive enhancement: real link. Datastar intercepts click to load modal fragment. -->
    <a
      class="button is-small is-info"
      href="/inventory/edit/<?= $id ?>"
      data-on:click="evt.preventDefault(); @get(el.href)"
    >
      Edit
    </a>
  </td>
</tr>
PHTML

cat > templates/inventory/_modal.phtml <<'PHTML'
<?php
/**
 * @var array{id:int, sku:string, name:string, stock:int} $product
 * @var array<string, string> $errors
 * @var mixed $submittedStock
 * @var string $csrfToken
 */
$id = (int) ($product['id'] ?? 0);
$sku = (string) ($product['sku'] ?? '');
$name = (string) ($product['name'] ?? '');
$errors = is_array($errors ?? null) ? $errors : [];
$csrfToken = (string) ($csrfToken ?? '');

$rawStock = $submittedStock !== null ? $submittedStock : ($product['stock'] ?? 0);
$hasStockError = array_key_exists('stock', $errors);

$signalsJson = json_encode(
  ['stock' => $rawStock],
  JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
);
?>
<div id="modal-container">
  <div class="modal is-active">
    <div
      class="modal-background"
      role="button"
      tabindex="0"
      aria-label="Close"
      data-on:click="el.closest('#modal-container').replaceChildren()"
    ></div>

    <form
      class="modal-card"
      method="post"
      action="/inventory/save/<?= $id ?>"
      data-signals='<?= $this->escapeHtmlAttr((string) $signalsJson) ?>'
      data-indicator="saving"
      data-on:submit="@post(el.action, {contentType: 'form'})"
    >
      <input
        type="hidden"
        name="<?= $this->escapeHtmlAttr(\App\Security\Csrf::fieldName()) ?>"
        value="<?= $this->escapeHtmlAttr($csrfToken) ?>"
      />

      <header class="modal-card-head">
        <p class="modal-card-title">
          Edit <?= $this->escapeHtml($sku) ?>
        </p>
        <button
          class="delete"
          aria-label="close"
          type="button"
          data-on:click="el.closest('#modal-container').replaceChildren()"
        ></button>
      </header>

      <section class="modal-card-body">
        <div class="content">
          <p><strong><?= $this->escapeHtml($name) ?></strong></p>
        </div>

        <div class="field">
          <label class="label" for="stock">Stock</label>
          <div class="control">
            <input
              id="stock"
              class="input <?= $hasStockError ? 'is-danger' : '' ?>"
              type="number"
              name="stock"
              min="0"
              step="1"
              value="<?= $this->escapeHtmlAttr((string) $rawStock) ?>"
              data-bind="stock"
              data-attr:aria-invalid="<?= $hasStockError ? 'true' : 'false' ?>"
            />
          </div>

          <?php if ($hasStockError): ?>
            <p class="help is-danger">
              <?= $this->escapeHtml((string) $errors['stock']) ?>
            </p>
          <?php else: ?>
            <p class="help">Non-negative integer.</p>
          <?php endif; ?>
        </div>
      </section>

      <footer class="modal-card-foot">
        <button
          class="button is-success"
          type="submit"
          data-class:is-loading="$saving"
          data-attr:disabled="$saving"
        >
          Save
        </button>

        <button
          class="button"
          type="button"
          data-on:click="el.closest('#modal-container').replaceChildren()"
        >
          Cancel
        </button>
      </footer>
    </form>
  </div>
</div>
PHTML

sqlite3 var/app.db <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;

DROP TABLE IF EXISTS products;

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  stock INTEGER NOT NULL
);

WITH RECURSIVE seq(x) AS (
  SELECT 1
  UNION ALL
  SELECT x + 1 FROM seq WHERE x < 60
)
INSERT INTO products (sku, name, stock)
SELECT
  'SKU-' || printf('%04d', x),
  'Product ' || x,
  (x * 3) % 47
FROM seq;
SQL

echo ""
echo "Scaffold complete."
echo ""
echo "Next:"
echo "  cd $PROJECT_NAME"
echo "  composer install"
echo ""
echo "Run:"
echo "  composer run dev:sapi"
echo ""
echo "Open:"
echo "  http://127.0.0.1:8080"
echo ""
