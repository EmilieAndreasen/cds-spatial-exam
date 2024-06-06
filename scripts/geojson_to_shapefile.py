import fiona
import json
from shapely.geometry import shape, mapping
from fiona.crs import from_epsg

# Load GeoJSON file
with open('/work/CDS-Spatial/in/shelters_reprojected.geojson') as f:
    geojson_data = json.load(f)

# Define schema for the shapefile
schema = {
    'geometry': 'Point',
    'properties': {
        'uuid': 'str',  # Adjust if UUID should be treated as string
        'identifier': 'str',
        'createdBy': 'str',
        'createdAt': 'str',  # assuming date is stored as string
        'FeatureType': 'str',
        'Northing': 'float',
        'Easting': 'float',
        'LocaleDesc': 'str'
    }
}

# Create a new shapefile with the correct projection (WGS 84 / UTM ZONE 32N)
with fiona.open('/work/CDS-Spatial/out/shelters/shelters_reprojected.shp', 'w', driver='ESRI Shapefile', schema=schema, crs=from_epsg(32632)) as shp:
    for feature in geojson_data['features']:
        geom = shape(feature['geometry'])
        prop = feature['properties']
        properties = {
            'uuid': str(prop.get('uuid', '')),
            'identifier': prop.get('identifier', ''),
            'createdBy': prop.get('createdBy', ''),
            'createdAt': prop.get('createdAt', ''),
            'FeatureType': prop.get('FeatureType', ''),
            'Northing': float(prop.get('Northing', 0.0)),
            'Easting': float(prop.get('Easting', 0.0)),
            'LocaleDesc': prop.get('LocaleDesc', '')
        }
        shp.write({
            'geometry': mapping(geom),
            'properties': properties
        })

print("Conversion complete!")