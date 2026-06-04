from pathlib import Path
from dagster_dbt import DbtProject, DbtCliResource

DBT_DIR = Path(__file__).parents[3] / "p3_dbt_project"   # adjust depth to your layout
dbt_project = DbtProject(project_dir=DBT_DIR)
dbt_project.prepare_if_dev()          # auto-runs `dbt parse` → manifest
dbt_resource = DbtCliResource(project_dir=dbt_project)