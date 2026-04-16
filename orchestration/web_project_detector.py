#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
웹 프로젝트 자동 감지 기능 구현 (S-085)

프로젝트 디렉토리를 스캔하여 웹 프로젝트(React, Vue, Angular 등) 여부를 자동으로 감지합니다.
"""

import os
import json
import re
import time
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum


class WebProjectType(Enum):
    """웹 프로젝트 타입 열거형"""
    REACT = "react"
    VUE = "vue"
    ANGULAR = "angular"
    NEXTJS = "nextjs"
    NUXTJS = "nuxtjs"
    UNKNOWN = "unknown"


class PackageManager(Enum):
    """패키지 매니저 열거형"""
    NPM = "npm"
    YARN = "yarn"
    PNPM = "pnpm"
    UNKNOWN = "unknown"


class BuildTool(Enum):
    """빌드 도구 열거형"""
    WEBPACK = "webpack"
    VITE = "vite"
    ROLLUP = "rollup"
    PARCEL = "parcel"
    UNKNOWN = "unknown"


@dataclass
class WebProjectInfo:
    """웹 프로젝트 정보 데이터 클래스"""
    type: str  # WebProjectType 값
    package_manager: str  # PackageManager 값
    has_typescript: bool
    framework_version: Optional[str] = None
    build_tool: Optional[str] = None  # BuildTool 값
    config_files: List[str] = None
    entry_points: List[str] = None

    def __post_init__(self):
        if self.config_files is None:
            self.config_files = []
        if self.entry_points is None:
            self.entry_points = []


class WebProjectDetector:
    """웹 프로젝트 감지기"""

    def __init__(self, scan_depth: int = 3, timeout_seconds: int = 5):
        """
        웹 프로젝트 감지기 초기화

        Args:
            scan_depth: 스캔 깊이 (루트에서 최대 몇 단계 하위까지)
            timeout_seconds: 감지 시간 제한
        """
        self.scan_depth = scan_depth
        self.timeout_seconds = timeout_seconds

    def detect_project(self, project_path: str) -> WebProjectInfo:
        """
        프로젝트 디렉토리에서 웹 프로젝트 정보를 감지

        Args:
            project_path: 프로젝트 디렉토리 경로

        Returns:
            WebProjectInfo: 감지된 웹 프로젝트 정보
        """
        start_time = time.time()
        project_path = Path(project_path).resolve()

        try:
            # 타임아웃 체크
            if time.time() - start_time > self.timeout_seconds:
                raise TimeoutError("웹 프로젝트 감지 시간 초과")

            # package.json 파일 찾기 및 파싱
            package_json_path = project_path / "package.json"
            if not package_json_path.exists():
                return WebProjectInfo(
                    type=WebProjectType.UNKNOWN.value,
                    package_manager=PackageManager.UNKNOWN.value,
                    has_typescript=False
                )

            # 타임아웃 체크 (파일 I/O 전)
            if time.time() - start_time > self.timeout_seconds:
                raise TimeoutError("웹 프로젝트 감지 시간 초과")

            # package.json 내용 파싱
            with open(package_json_path, 'r', encoding='utf-8') as f:
                package_data = json.load(f)

            # 의존성 정보 수집
            dependencies = {}
            dependencies.update(package_data.get('dependencies', {}))
            dependencies.update(package_data.get('devDependencies', {}))

            # 타임아웃 체크 (의존성 분석 후)
            if time.time() - start_time > self.timeout_seconds:
                raise TimeoutError("웹 프로젝트 감지 시간 초과")

            # 프로젝트 타입 감지
            project_type = self._detect_project_type(project_path, dependencies)

            # 패키지 매니저 감지
            package_manager = self._detect_package_manager(project_path)

            # 타임아웃 체크 (패키지 매니저 감지 후)
            if time.time() - start_time > self.timeout_seconds:
                raise TimeoutError("웹 프로젝트 감지 시간 초과")

            # TypeScript 사용 여부 확인
            has_typescript = self._detect_typescript(project_path, dependencies)

            # 프레임워크 버전 감지
            framework_version = self._get_framework_version(project_type, dependencies)

            # 빌드 도구 감지
            build_tool = self._detect_build_tool(project_path, dependencies)

            # 타임아웃 체크 (빌드 도구 감지 후)
            if time.time() - start_time > self.timeout_seconds:
                raise TimeoutError("웹 프로젝트 감지 시간 초과")

            # 설정 파일 목록
            config_files = self._find_config_files(project_path, project_type)

            # 엔트리 포인트 감지
            entry_points = self._find_entry_points(project_path, project_type)

            return WebProjectInfo(
                type=project_type.value,
                package_manager=package_manager.value,
                has_typescript=has_typescript,
                framework_version=framework_version,
                build_tool=build_tool.value if build_tool else None,
                config_files=config_files,
                entry_points=entry_points
            )

        except TimeoutError as e:
            print(f"웹 프로젝트 감지 시간 초과: {e}")
            return WebProjectInfo(
                type=WebProjectType.UNKNOWN.value,
                package_manager=PackageManager.UNKNOWN.value,
                has_typescript=False
            )
        except (json.JSONDecodeError, FileNotFoundError, PermissionError) as e:
            print(f"웹 프로젝트 감지 중 파일 처리 오류: {e}")
            return WebProjectInfo(
                type=WebProjectType.UNKNOWN.value,
                package_manager=PackageManager.UNKNOWN.value,
                has_typescript=False
            )
        except Exception as e:
            print(f"웹 프로젝트 감지 중 예상치 못한 오류 발생: {e}")
            return WebProjectInfo(
                type=WebProjectType.UNKNOWN.value,
                package_manager=PackageManager.UNKNOWN.value,
                has_typescript=False
            )

    def _detect_project_type(self, project_path: Path, dependencies: Dict[str, str]) -> WebProjectType:
        """프로젝트 타입 감지"""

        # Next.js 감지 (React보다 우선)
        if 'next' in dependencies:
            nextjs_patterns = [
                'next.config.js', 'next.config.ts',
                'pages', 'app'  # Next.js 13+ app directory
            ]
            if any((project_path / pattern).exists() for pattern in nextjs_patterns):
                return WebProjectType.NEXTJS

        # Nuxt.js 감지 (Vue보다 우선)
        if 'nuxt' in dependencies:
            nuxtjs_patterns = [
                'nuxt.config.js', 'nuxt.config.ts',
                'pages'
            ]
            if any((project_path / pattern).exists() for pattern in nuxtjs_patterns):
                return WebProjectType.NUXTJS

        # Angular 감지
        if '@angular/core' in dependencies:
            angular_patterns = [
                'angular.json',
                'src/app/app.module.ts'
            ]
            if any((project_path / pattern).exists() for pattern in angular_patterns):
                return WebProjectType.ANGULAR

        # React 감지
        if 'react' in dependencies:
            react_patterns = [
                'src/App.js', 'src/App.tsx',
                'public/index.html'
            ]
            if any((project_path / pattern).exists() for pattern in react_patterns):
                return WebProjectType.REACT

        # Vue 감지
        if 'vue' in dependencies:
            vue_patterns = [
                'src/main.js', 'src/main.ts',
                'vue.config.js', 'vite.config.js'
            ]
            if any((project_path / pattern).exists() for pattern in vue_patterns):
                return WebProjectType.VUE

        return WebProjectType.UNKNOWN

    def _detect_package_manager(self, project_path: Path) -> PackageManager:
        """패키지 매니저 감지"""

        if (project_path / "yarn.lock").exists():
            return PackageManager.YARN
        elif (project_path / "pnpm-lock.yaml").exists():
            return PackageManager.PNPM
        elif (project_path / "package-lock.json").exists():
            return PackageManager.NPM
        else:
            return PackageManager.UNKNOWN

    def _detect_typescript(self, project_path: Path, dependencies: Dict[str, str]) -> bool:
        """TypeScript 사용 여부 감지"""

        # tsconfig.json 파일 존재 확인
        if (project_path / "tsconfig.json").exists():
            return True

        # TypeScript 의존성 확인
        ts_dependencies = ['typescript', '@types/node', '@types/react', '@types/vue']
        if any(dep in dependencies for dep in ts_dependencies):
            return True

        # .ts, .tsx 파일 존재 확인 (성능 최적화: 첫 번째 발견 시 즉시 반환)
        for ext in ["**/*.ts", "**/*.tsx"]:
            try:
                next(project_path.glob(ext))
                return True
            except StopIteration:
                continue
        return False

    def _get_framework_version(self, project_type: WebProjectType, dependencies: Dict[str, str]) -> Optional[str]:
        """프레임워크 버전 추출"""

        framework_map = {
            WebProjectType.REACT: 'react',
            WebProjectType.VUE: 'vue',
            WebProjectType.ANGULAR: '@angular/core',
            WebProjectType.NEXTJS: 'next',
            WebProjectType.NUXTJS: 'nuxt'
        }

        framework_dep = framework_map.get(project_type)
        if framework_dep and framework_dep in dependencies:
            version = dependencies[framework_dep]
            # semver 범위 지시자 제거 (^, ~, >=, > 등)
            # 시작 부분의 버전 범위 지시자들을 제거
            cleaned_version = re.sub(r'^[\^~>=<]+', '', version)
            return cleaned_version

        return None

    def _detect_build_tool(self, project_path: Path, dependencies: Dict[str, str]) -> Optional[BuildTool]:
        """빌드 도구 감지"""

        # Vite 감지
        if 'vite' in dependencies or (project_path / "vite.config.js").exists() or (project_path / "vite.config.ts").exists():
            return BuildTool.VITE

        # Webpack 감지
        if 'webpack' in dependencies or (project_path / "webpack.config.js").exists():
            return BuildTool.WEBPACK

        # Rollup 감지
        if 'rollup' in dependencies or (project_path / "rollup.config.js").exists():
            return BuildTool.ROLLUP

        # Parcel 감지
        if 'parcel' in dependencies:
            return BuildTool.PARCEL

        return None

    def _find_config_files(self, project_path: Path, project_type: WebProjectType) -> List[str]:
        """설정 파일 목록 수집"""

        config_patterns = [
            'package.json', 'tsconfig.json',
            'webpack.config.js', 'vite.config.js', 'vite.config.ts',
            'rollup.config.js', 'parcel.config.js',
            'babel.config.js', '.babelrc',
            'eslint.config.js', '.eslintrc.js', '.eslintrc.json',
            'prettier.config.js', '.prettierrc'
        ]

        # 프로젝트 타입별 추가 설정 파일
        if project_type == WebProjectType.ANGULAR:
            config_patterns.extend(['angular.json', 'karma.conf.js', 'protractor.conf.js'])
        elif project_type == WebProjectType.VUE:
            config_patterns.extend(['vue.config.js'])
        elif project_type == WebProjectType.NEXTJS:
            config_patterns.extend(['next.config.js', 'next.config.ts'])
        elif project_type == WebProjectType.NUXTJS:
            config_patterns.extend(['nuxt.config.js', 'nuxt.config.ts'])

        found_files = []
        for pattern in config_patterns:
            file_path = project_path / pattern
            if file_path.exists():
                # 경로 구분자를 통일 (Windows 호환성)
                relative_path = str(file_path.relative_to(project_path)).replace('\\', '/')
                found_files.append(relative_path)

        return found_files

    def _find_entry_points(self, project_path: Path, project_type: WebProjectType) -> List[str]:
        """엔트리 포인트 감지"""

        entry_patterns = []

        if project_type == WebProjectType.REACT:
            entry_patterns = ['src/index.js', 'src/index.tsx', 'src/App.js', 'src/App.tsx']
        elif project_type == WebProjectType.VUE:
            entry_patterns = ['src/main.js', 'src/main.ts', 'src/App.vue']
        elif project_type == WebProjectType.ANGULAR:
            entry_patterns = ['src/main.ts', 'src/app/app.module.ts']
        elif project_type == WebProjectType.NEXTJS:
            entry_patterns = ['pages/_app.js', 'pages/_app.tsx', 'app/layout.js', 'app/layout.tsx']
        elif project_type == WebProjectType.NUXTJS:
            entry_patterns = ['pages/index.vue', 'app.vue']

        found_entries = []
        for pattern in entry_patterns:
            entry_path = project_path / pattern
            if entry_path.exists():
                # 경로 구분자를 통일 (Windows 호환성)
                relative_path = str(entry_path.relative_to(project_path)).replace('\\', '/')
                found_entries.append(relative_path)

        return found_entries


def main():
    """메인 함수 - CLI로 사용할 때"""
    import sys
    import argparse

    parser = argparse.ArgumentParser(description="웹 프로젝트 자동 감지 도구")
    parser.add_argument("project_path", help="분석할 프로젝트 디렉토리 경로")
    parser.add_argument("--output", "-o", help="결과를 저장할 JSON 파일 경로")
    parser.add_argument("--verbose", "-v", action="store_true", help="상세 출력")

    args = parser.parse_args()

    # 웹 프로젝트 감지 수행
    detector = WebProjectDetector()
    result = detector.detect_project(args.project_path)

    # 결과 출력
    result_dict = asdict(result)

    if args.verbose:
        print(f"프로젝트 경로: {args.project_path}")
        print(f"감지 결과:")
        for key, value in result_dict.items():
            print(f"  {key}: {value}")
    else:
        print(json.dumps(result_dict, ensure_ascii=False, indent=2))

    # 파일 저장
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(result_dict, f, ensure_ascii=False, indent=2)
        print(f"결과가 {args.output}에 저장되었습니다.")

    return 0


if __name__ == "__main__":
    exit(main())