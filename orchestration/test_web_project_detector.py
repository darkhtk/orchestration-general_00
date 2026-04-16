#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
웹 프로젝트 감지기 단위 테스트

SPEC-S-085의 수용 기준을 만족하는지 검증합니다.
"""

import os
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, mock_open

from web_project_detector import (
    WebProjectDetector, WebProjectInfo,
    WebProjectType, PackageManager, BuildTool
)


class TestWebProjectDetector(unittest.TestCase):
    """웹 프로젝트 감지기 테스트"""

    def setUp(self):
        """테스트 설정"""
        self.detector = WebProjectDetector(scan_depth=3, timeout_seconds=5)
        self.temp_dir = tempfile.mkdtemp()
        self.test_project_path = Path(self.temp_dir)

    def tearDown(self):
        """테스트 정리"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _create_file(self, relative_path: str, content: str = ""):
        """테스트용 파일 생성"""
        file_path = self.test_project_path / relative_path
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding='utf-8')
        return file_path

    def _create_package_json(self, dependencies: dict = None, dev_dependencies: dict = None):
        """package.json 파일 생성"""
        package_data = {
            "name": "test-project",
            "version": "1.0.0"
        }

        if dependencies:
            package_data["dependencies"] = dependencies

        if dev_dependencies:
            package_data["devDependencies"] = dev_dependencies

        content = json.dumps(package_data, indent=2)
        self._create_file("package.json", content)

    def test_detect_react_project(self):
        """React 프로젝트 감지 테스트"""
        # React 프로젝트 설정
        self._create_package_json({"react": "^18.0.0", "react-dom": "^18.0.0"})
        self._create_file("src/App.js")
        self._create_file("public/index.html")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.REACT.value)
        self.assertEqual(result.framework_version, "18.0.0")
        self.assertIn("src/App.js", result.entry_points)
        self.assertIn("package.json", result.config_files)

    def test_detect_vue_project(self):
        """Vue 프로젝트 감지 테스트"""
        # Vue 프로젝트 설정
        self._create_package_json({"vue": "^3.0.0"})
        self._create_file("src/main.js")
        self._create_file("vite.config.js")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.VUE.value)
        self.assertEqual(result.framework_version, "3.0.0")
        self.assertIn("src/main.js", result.entry_points)
        self.assertIn("vite.config.js", result.config_files)

    def test_detect_angular_project(self):
        """Angular 프로젝트 감지 테스트"""
        # Angular 프로젝트 설정
        self._create_package_json({"@angular/core": "^16.0.0"})
        self._create_file("angular.json")
        self._create_file("src/app/app.module.ts")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.ANGULAR.value)
        self.assertEqual(result.framework_version, "16.0.0")
        self.assertIn("src/app/app.module.ts", result.entry_points)  # Angular 엔트리 포인트
        self.assertIn("angular.json", result.config_files)

    def test_detect_nextjs_project(self):
        """Next.js 프로젝트 감지 테스트"""
        # Next.js 프로젝트 설정
        self._create_package_json({"next": "^13.0.0", "react": "^18.0.0"})
        self._create_file("next.config.js")
        self._create_file("pages/index.js")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.NEXTJS.value)
        self.assertEqual(result.framework_version, "13.0.0")
        self.assertIn("next.config.js", result.config_files)

    def test_detect_nuxtjs_project(self):
        """Nuxt.js 프로젝트 감지 테스트"""
        # Nuxt.js 프로젝트 설정
        self._create_package_json({"nuxt": "^3.0.0"})
        self._create_file("nuxt.config.js")
        self._create_file("pages/index.vue")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.NUXTJS.value)
        self.assertEqual(result.framework_version, "3.0.0")
        self.assertIn("nuxt.config.js", result.config_files)

    def test_detect_package_manager_yarn(self):
        """Yarn 패키지 매니저 감지 테스트"""
        self._create_package_json({"react": "^18.0.0"})
        self._create_file("yarn.lock")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.package_manager, PackageManager.YARN.value)

    def test_detect_package_manager_pnpm(self):
        """PNPM 패키지 매니저 감지 테스트"""
        self._create_package_json({"react": "^18.0.0"})
        self._create_file("pnpm-lock.yaml")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.package_manager, PackageManager.PNPM.value)

    def test_detect_package_manager_npm(self):
        """NPM 패키지 매니저 감지 테스트"""
        self._create_package_json({"react": "^18.0.0"})
        self._create_file("package-lock.json")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.package_manager, PackageManager.NPM.value)

    def test_detect_typescript_usage(self):
        """TypeScript 사용 여부 감지 테스트"""
        # TypeScript 프로젝트 설정
        self._create_package_json(
            dependencies={"react": "^18.0.0"},
            dev_dependencies={"typescript": "^4.9.0"}
        )
        self._create_file("tsconfig.json")
        self._create_file("src/App.tsx")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertTrue(result.has_typescript)

    def test_detect_build_tool_vite(self):
        """Vite 빌드 도구 감지 테스트"""
        self._create_package_json(
            dependencies={"vue": "^3.0.0"},
            dev_dependencies={"vite": "^4.0.0"}
        )
        self._create_file("vite.config.js")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.build_tool, BuildTool.VITE.value)

    def test_detect_build_tool_webpack(self):
        """Webpack 빌드 도구 감지 테스트"""
        self._create_package_json(
            dependencies={"react": "^18.0.0"},
            dev_dependencies={"webpack": "^5.0.0"}
        )
        self._create_file("webpack.config.js")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.build_tool, BuildTool.WEBPACK.value)

    def test_no_package_json_returns_unknown(self):
        """package.json이 없을 때 unknown 반환 테스트"""
        # package.json 없이 테스트
        self._create_file("src/index.html")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.UNKNOWN.value)
        self.assertEqual(result.package_manager, PackageManager.UNKNOWN.value)
        self.assertFalse(result.has_typescript)

    def test_malformed_package_json_handling(self):
        """잘못된 package.json 처리 테스트"""
        # 잘못된 JSON 파일 생성
        self._create_file("package.json", "{ invalid json }")

        result = self.detector.detect_project(str(self.test_project_path))

        self.assertEqual(result.type, WebProjectType.UNKNOWN.value)

    def test_permission_error_handling(self):
        """권한 오류 처리 테스트"""
        # 존재하지 않는 디렉토리로 테스트
        nonexistent_path = "/nonexistent/path/to/project"

        result = self.detector.detect_project(nonexistent_path)

        self.assertEqual(result.type, WebProjectType.UNKNOWN.value)

    def test_timeout_handling(self):
        """타임아웃 처리 테스트"""
        # 매우 짧은 타임아웃으로 감지기 생성
        quick_detector = WebProjectDetector(timeout_seconds=0.001)
        self._create_package_json({"react": "^18.0.0"})

        result = quick_detector.detect_project(str(self.test_project_path))

        # 타임아웃이 발생했을 수도 있지만, 결과는 여전히 유효해야 함
        self.assertIsInstance(result, WebProjectInfo)

    def test_config_files_detection(self):
        """설정 파일 감지 테스트"""
        self._create_package_json({"react": "^18.0.0"})
        self._create_file("tsconfig.json")
        self._create_file("webpack.config.js")
        self._create_file(".eslintrc.js")

        result = self.detector.detect_project(str(self.test_project_path))

        expected_configs = ["package.json", "tsconfig.json", "webpack.config.js", ".eslintrc.js"]
        for config in expected_configs:
            self.assertIn(config, result.config_files)

    def test_entry_points_detection(self):
        """엔트리 포인트 감지 테스트"""
        self._create_package_json({"react": "^18.0.0"})
        self._create_file("src/index.js")
        self._create_file("src/App.js")  # React 감지를 위해 App.js 필요
        self._create_file("public/index.html")  # React 감지를 위해 public/index.html 필요

        result = self.detector.detect_project(str(self.test_project_path))

        # React 프로젝트의 엔트리 포인트가 감지되어야 함
        self.assertTrue(any("src/" in entry for entry in result.entry_points))

    def test_framework_priority_nextjs_over_react(self):
        """프레임워크 우선순위 테스트: Next.js > React"""
        self._create_package_json({"next": "^13.0.0", "react": "^18.0.0"})
        self._create_file("next.config.js")
        self._create_file("pages/index.js")

        result = self.detector.detect_project(str(self.test_project_path))

        # Next.js가 React보다 우선시되어야 함
        self.assertEqual(result.type, WebProjectType.NEXTJS.value)

    def test_framework_priority_nuxtjs_over_vue(self):
        """프레임워크 우선순위 테스트: Nuxt.js > Vue"""
        self._create_package_json({"nuxt": "^3.0.0", "vue": "^3.0.0"})
        self._create_file("nuxt.config.js")
        self._create_file("pages/index.vue")

        result = self.detector.detect_project(str(self.test_project_path))

        # Nuxt.js가 Vue보다 우선시되어야 함
        self.assertEqual(result.type, WebProjectType.NUXTJS.value)


class TestWebProjectInfo(unittest.TestCase):
    """WebProjectInfo 데이터 클래스 테스트"""

    def test_web_project_info_creation(self):
        """WebProjectInfo 객체 생성 테스트"""
        info = WebProjectInfo(
            type=WebProjectType.REACT.value,
            package_manager=PackageManager.YARN.value,
            has_typescript=True,
            framework_version="18.0.0",
            build_tool=BuildTool.VITE.value,
            config_files=["package.json", "tsconfig.json"],
            entry_points=["src/index.tsx"]
        )

        self.assertEqual(info.type, "react")
        self.assertEqual(info.package_manager, "yarn")
        self.assertTrue(info.has_typescript)
        self.assertEqual(info.framework_version, "18.0.0")
        self.assertEqual(info.build_tool, "vite")
        self.assertIn("package.json", info.config_files)
        self.assertIn("src/index.tsx", info.entry_points)

    def test_web_project_info_default_values(self):
        """WebProjectInfo 기본값 테스트"""
        info = WebProjectInfo(
            type=WebProjectType.UNKNOWN.value,
            package_manager=PackageManager.UNKNOWN.value,
            has_typescript=False
        )

        self.assertEqual(info.config_files, [])
        self.assertEqual(info.entry_points, [])
        self.assertIsNone(info.framework_version)
        self.assertIsNone(info.build_tool)


if __name__ == "__main__":
    # 테스트 실행
    unittest.main(verbosity=2)