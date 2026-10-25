"""Create a native Garmin application .SET file; prompt for the token privately.

Binary format reference: https://github.com/cyberang3l/GarminSettingsFileParser
This independent serializer uses only Python's standard library.
"""
import argparse
import getpass
from pathlib import Path
import struct
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]

def encode_settings(values):
    table=bytearray()
    offsets={}
    def string(value):
        if value not in offsets:
            encoded=value.encode('utf-8')+b'\0'
            if len(encoded)>65535: raise ValueError('Setting string is too long')
            offsets[value]=len(table)
            table.extend(struct.pack('>H',len(encoded))+encoded)
        return b'\x03'+struct.pack('>I',offsets[value])
    body=bytearray(b'\x0b'+struct.pack('>I',len(values)))
    for key,value in values.items():
        body.extend(string(key))
        if isinstance(value,bool): body.extend(b'\x09'+bytes([value]))
        elif isinstance(value,int): body.extend(b'\x01'+struct.pack('>i',value))
        elif isinstance(value,str): body.extend(string(value))
        else: raise TypeError('Unsupported application property type')
    return b'\xab\xcd\xab\xcd'+struct.pack('>I',len(table))+table+b'\xda\x7a\xda\x7a'+struct.pack('>I',len(body))+body

def defaults():
    result={}
    for element in ET.parse(ROOT/'klikavec-settings/properties.xml').getroot():
        value=element.text or ''
        if element.attrib['type']=='boolean': value=value=='true'
        elif element.attrib['type']=='number': value=int(value)
        result[element.attrib['id']]=value
    return result

def main():
    parser=argparse.ArgumentParser(description='Soukromé nativní nastavení Klikavec Home pro sideload.')
    parser.add_argument('--api-url',required=True,help='https://HA_HOST/api')
    parser.add_argument('--output',type=Path,required=True,help='Soukromý soubor mimo repozitář, název KLIKAVECHOME.SET')
    parser.add_argument('--config-url',default='',help='Volitelný soukromý JSON endpoint na stejném HA hostu')
    args=parser.parse_args()
    url=urlsplit(args.api_url)
    if url.scheme!='https' or not url.hostname or url.username or url.password or not url.path.endswith('/api') or url.query or url.fragment:
        parser.error('API musí být HTTPS URL končící /api, bez hesla, query a fragmentu.')
    if args.config_url:
        config=urlsplit(args.config_url)
        if (config.scheme,config.netloc)!=(url.scheme,url.netloc): parser.error('Konfigurace musí mít stejný HTTPS host.')
    output=args.output.resolve()
    if output.is_relative_to(ROOT): parser.error('Tajné nastavení musí zůstat mimo Git repozitář.')
    if output.exists(): parser.error('Výstup už existuje; vyber nový soubor. Existující nastavení se nepřepisuje.')
    if not output.parent.is_dir(): parser.error('Cílová složka musí existovat.')
    token=getpass.getpass('HA token (skrytý vstup): ').strip()
    if not token or any(c.isspace() for c in token): parser.error('Token je prázdný nebo obsahuje mezery.')
    values=defaults()
    values.update(api_key=token,api_url=args.api_url,config_url=args.config_url,
        user_http_header1_name='User-Agent',user_http_header1_value='KlikavecHome-Garmin/1.0')
    with output.open('xb') as target: target.write(encode_settings(values))
    output.chmod(0o600)
    print('Nativní nastavení vytvořeno. Soubor obsahuje token; nesdílej ho.')

if __name__=='__main__': main()
