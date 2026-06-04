from dagster import Definitions
from .assets import bronze_raw_commerce, dbt_models
from .resources import dbt_resource
from olist_orchestration import assets  # noqa: TID252


defs = Definitions(
    assets=[bronze_raw_commerce, dbt_models],
    resources={"dbt": dbt_resource},
)