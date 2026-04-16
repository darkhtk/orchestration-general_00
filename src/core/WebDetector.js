/**
 * WebDetector - 웹 프로젝트 자동 감지 기능
 *
 * 프로젝트 디렉토리를 스캔하여 웹 프로젝트 타입을 자동으로 감지
 * React, Vue, Angular, Next.js, Nuxt.js 등의 프레임워크 지원
 */

const fs = require('fs');
const path = require('path');

/**
 * @typedef {Object} WebProjectInfo
 * @property {'react' | 'vue' | 'angular' | 'nextjs' | 'nuxtjs' | 'unknown'} type - 프로젝트 타입
 * @property {'npm' | 'yarn' | 'pnpm' | 'unknown'} packageManager - 패키지 매니저
 * @property {boolean} hasTypeScript - TypeScript 사용 여부
 * @property {string} [frameworkVersion] - 프레임워크 버전
 * @property {'webpack' | 'vite' | 'rollup' | 'parcel'} [buildTool] - 빌드 도구
 * @property {string[]} configFiles - 설정 파일 목록
 * @property {string[]} entryPoints - 엔트리 포인트 목록
 */

class WebDetector {
    constructor() {
        this.cache = new Map();
        this.cacheTimeout = 60 * 60 * 1000; // 1시간
        this.scanDepth = 3;
        this.timeoutMs = 5000; // 5초
    }

    /**
     * 프로젝트 디렉토리를 스캔하여 웹 프로젝트 정보 감지
     * @param {string} projectPath - 프로젝트 디렉토리 경로
     * @returns {Promise<WebProjectInfo>} 웹 프로젝트 정보
     */
    async scan(projectPath) {
        try {
            // 캐시 확인
            const cacheKey = path.resolve(projectPath);
            const cached = this.cache.get(cacheKey);
            if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
                return cached.data;
            }

            // 타임아웃 처리
            const result = await Promise.race([
                this._performScan(projectPath),
                new Promise((_, reject) =>
                    setTimeout(() => reject(new Error('스캔 시간 초과')), this.timeoutMs)
                )
            ]);

            // 캐시 저장
            this.cache.set(cacheKey, {
                data: result,
                timestamp: Date.now()
            });

            return result;
        } catch (error) {
            console.error('웹 프로젝트 감지 실패:', error);
            return this._createDefaultResult();
        }
    }

    /**
     * 실제 스캔 수행
     * @private
     */
    async _performScan(projectPath) {
        const result = this._createDefaultResult();

        // package.json 확인
        const packageJson = await this._readPackageJson(projectPath);
        if (!packageJson) {
            return result;
        }

        // 프레임워크 타입 감지
        result.type = this._detectFrameworkType(packageJson, projectPath);
        result.frameworkVersion = this._getFrameworkVersion(packageJson, result.type);

        // TypeScript 감지
        result.hasTypeScript = this._detectTypeScript(packageJson, projectPath);

        // 패키지 매니저 감지
        result.packageManager = this._detectPackageManager(projectPath);

        // 빌드 도구 감지
        result.buildTool = this._detectBuildTool(packageJson, projectPath);

        // 설정 파일 목록
        result.configFiles = this._findConfigFiles(projectPath, result.type);

        // 엔트리 포인트 목록
        result.entryPoints = this._findEntryPoints(projectPath, result.type);

        return result;
    }

    /**
     * package.json 파일 읽기
     * @private
     */
    async _readPackageJson(projectPath) {
        try {
            const packagePath = path.join(projectPath, 'package.json');
            const content = fs.readFileSync(packagePath, 'utf8');
            return JSON.parse(content);
        } catch (error) {
            return null;
        }
    }

    /**
     * 프레임워크 타입 감지
     * @private
     */
    _detectFrameworkType(packageJson, projectPath) {
        const dependencies = {
            ...packageJson.dependencies,
            ...packageJson.devDependencies
        };

        // Next.js 감지 (React보다 먼저 확인)
        if (dependencies.next) {
            const hasNextConfig = fs.existsSync(path.join(projectPath, 'next.config.js')) ||
                                fs.existsSync(path.join(projectPath, 'next.config.ts'));
            const hasPagesDir = fs.existsSync(path.join(projectPath, 'pages'));
            const hasAppDir = fs.existsSync(path.join(projectPath, 'app'));

            if (hasNextConfig && (hasPagesDir || hasAppDir)) {
                return 'nextjs';
            }
        }

        // Nuxt.js 감지 (Vue보다 먼저 확인)
        if (dependencies.nuxt) {
            const hasNuxtConfig = fs.existsSync(path.join(projectPath, 'nuxt.config.js')) ||
                                fs.existsSync(path.join(projectPath, 'nuxt.config.ts'));
            const hasPagesDir = fs.existsSync(path.join(projectPath, 'pages'));

            if (hasNuxtConfig && hasPagesDir) {
                return 'nuxtjs';
            }
        }

        // Angular 감지
        if (dependencies['@angular/core']) {
            const hasAngularJson = fs.existsSync(path.join(projectPath, 'angular.json'));
            const hasAppModule = fs.existsSync(path.join(projectPath, 'src/app/app.module.ts'));

            if (hasAngularJson && hasAppModule) {
                return 'angular';
            }
        }

        // React 감지
        if (dependencies.react) {
            const hasAppJs = fs.existsSync(path.join(projectPath, 'src/App.js'));
            const hasAppTsx = fs.existsSync(path.join(projectPath, 'src/App.tsx'));
            const hasPublicIndex = fs.existsSync(path.join(projectPath, 'public/index.html'));

            if ((hasAppJs || hasAppTsx) && hasPublicIndex) {
                return 'react';
            }
        }

        // Vue 감지
        if (dependencies.vue) {
            const hasMainJs = fs.existsSync(path.join(projectPath, 'src/main.js'));
            const hasMainTs = fs.existsSync(path.join(projectPath, 'src/main.ts'));
            const hasVueConfig = fs.existsSync(path.join(projectPath, 'vue.config.js')) ||
                               fs.existsSync(path.join(projectPath, 'vite.config.js'));

            if ((hasMainJs || hasMainTs) && hasVueConfig) {
                return 'vue';
            }
        }

        return 'unknown';
    }

    /**
     * 프레임워크 버전 추출
     * @private
     */
    _getFrameworkVersion(packageJson, type) {
        const dependencies = {
            ...packageJson.dependencies,
            ...packageJson.devDependencies
        };

        const frameworkMap = {
            'react': 'react',
            'vue': 'vue',
            'angular': '@angular/core',
            'nextjs': 'next',
            'nuxtjs': 'nuxt'
        };

        const dependencyName = frameworkMap[type];
        return dependencyName ? dependencies[dependencyName] : undefined;
    }

    /**
     * TypeScript 사용 여부 감지
     * @private
     */
    _detectTypeScript(packageJson, projectPath) {
        const dependencies = {
            ...packageJson.dependencies,
            ...packageJson.devDependencies
        };

        // TypeScript 의존성 확인
        if (dependencies.typescript) {
            return true;
        }

        // tsconfig.json 파일 확인
        if (fs.existsSync(path.join(projectPath, 'tsconfig.json'))) {
            return true;
        }

        // .ts 또는 .tsx 파일 존재 확인
        const srcPath = path.join(projectPath, 'src');
        if (fs.existsSync(srcPath)) {
            try {
                const files = this._walkDirectory(srcPath, 2);
                return files.some(file => file.endsWith('.ts') || file.endsWith('.tsx'));
            } catch (error) {
                return false;
            }
        }

        return false;
    }

    /**
     * 패키지 매니저 감지
     * @private
     */
    _detectPackageManager(projectPath) {
        if (fs.existsSync(path.join(projectPath, 'pnpm-lock.yaml'))) {
            return 'pnpm';
        }
        if (fs.existsSync(path.join(projectPath, 'yarn.lock'))) {
            return 'yarn';
        }
        if (fs.existsSync(path.join(projectPath, 'package-lock.json'))) {
            return 'npm';
        }
        return 'unknown';
    }

    /**
     * 빌드 도구 감지
     * @private
     */
    _detectBuildTool(packageJson, projectPath) {
        const dependencies = {
            ...packageJson.dependencies,
            ...packageJson.devDependencies
        };

        // Vite 감지
        if (dependencies.vite || fs.existsSync(path.join(projectPath, 'vite.config.js'))) {
            return 'vite';
        }

        // Webpack 감지
        if (dependencies.webpack || fs.existsSync(path.join(projectPath, 'webpack.config.js'))) {
            return 'webpack';
        }

        // Rollup 감지
        if (dependencies.rollup || fs.existsSync(path.join(projectPath, 'rollup.config.js'))) {
            return 'rollup';
        }

        // Parcel 감지
        if (dependencies.parcel) {
            return 'parcel';
        }

        return undefined;
    }

    /**
     * 설정 파일 목록 찾기
     * @private
     */
    _findConfigFiles(projectPath, type) {
        const configs = [];
        const commonConfigs = [
            'package.json',
            'tsconfig.json',
            'babel.config.js',
            '.babelrc',
            'eslint.config.js',
            '.eslintrc.js',
            'prettier.config.js',
            '.prettierrc'
        ];

        const typeSpecificConfigs = {
            'react': ['webpack.config.js', 'craco.config.js'],
            'vue': ['vue.config.js', 'vite.config.js'],
            'angular': ['angular.json', 'karma.conf.js'],
            'nextjs': ['next.config.js', 'next.config.ts'],
            'nuxtjs': ['nuxt.config.js', 'nuxt.config.ts']
        };

        const allConfigs = [...commonConfigs, ...(typeSpecificConfigs[type] || [])];

        allConfigs.forEach(config => {
            if (fs.existsSync(path.join(projectPath, config))) {
                configs.push(config);
            }
        });

        return configs;
    }

    /**
     * 엔트리 포인트 목록 찾기
     * @private
     */
    _findEntryPoints(projectPath, type) {
        const entryPoints = [];

        const typeSpecificEntries = {
            'react': ['src/index.js', 'src/index.tsx', 'src/App.js', 'src/App.tsx'],
            'vue': ['src/main.js', 'src/main.ts'],
            'angular': ['src/main.ts', 'src/app/app.module.ts'],
            'nextjs': ['pages/_app.js', 'pages/_app.tsx', 'app/layout.js', 'app/layout.tsx'],
            'nuxtjs': ['app.vue', 'layouts/default.vue']
        };

        const entries = typeSpecificEntries[type] || [];

        entries.forEach(entry => {
            if (fs.existsSync(path.join(projectPath, entry))) {
                entryPoints.push(entry);
            }
        });

        return entryPoints;
    }

    /**
     * 디렉토리 순회
     * @private
     */
    _walkDirectory(dirPath, maxDepth, currentDepth = 0) {
        const files = [];

        if (currentDepth >= maxDepth) {
            return files;
        }

        try {
            const items = fs.readdirSync(dirPath);

            items.forEach(item => {
                const itemPath = path.join(dirPath, item);
                const stats = fs.statSync(itemPath);

                if (stats.isFile()) {
                    files.push(itemPath);
                } else if (stats.isDirectory() && !item.startsWith('.')) {
                    files.push(...this._walkDirectory(itemPath, maxDepth, currentDepth + 1));
                }
            });
        } catch (error) {
            // 권한 없음 등의 에러는 무시
        }

        return files;
    }

    /**
     * 기본 결과 객체 생성
     * @private
     */
    _createDefaultResult() {
        return {
            type: 'unknown',
            packageManager: 'unknown',
            hasTypeScript: false,
            frameworkVersion: undefined,
            buildTool: undefined,
            configFiles: [],
            entryPoints: []
        };
    }

    /**
     * 캐시 정리
     */
    clearCache() {
        this.cache.clear();
    }
}

module.exports = WebDetector;