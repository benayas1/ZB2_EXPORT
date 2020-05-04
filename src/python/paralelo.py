import pandas as pd
import lxml as lxml
import glob as glob
from lxml import etree
from tqdm import tqdm


# Read file containing B2 cluster in XML format
def read_file(b2_path, wildcard=False, period=None):
    f = b2_path
    if wildcard:
        files = glob.glob(b2_path)
        files.sort(reverse=True)
        if period is None:
            f = files[0]
            print(f)
        else:
            files = [ file for file in files if file.split("_")[3][:6] == period ]
            f = files[0]
            print(f)
            
    return (etree.parse(f), f.split("_")[3][:6])


# Class to store employee's B2 tables
class Pernr:
    def __init__(self, pernr, data):
        self.pernr = pernr
        
        # Read tables
        self.tables = {}
        xpath_tables = "./*[starts-with(local-name(), 'T_')]"
        elements = data.xpath(xpath_tables)
        for t in elements:
            tablename = t.tag[2:]
            self.tables[tablename] = self._read_table_(tablename, t)
        
    def _read_table_(self, tablename, data):
        xpath = './' + tablename
        elements = data.xpath(xpath)
        table = []
        for t in elements:
            e = {}
            for d in t:
                e[d.tag] = d.text
            table.append(e)
        return pd.DataFrame(table)

# Returns a dict of Pernr objects, by key        
def read_objects(b2_path, wildcard=False):        
    doc = read_file(b2_path, wildcard=wildcard)
    btags = doc.xpath('//ZST_B2')
    b2 = {}
    for b in tqdm(btags):
        number = b.xpath('./PERNR/text()')
        pernr = Pernr(number[0], b.xpath('./DATA')[0] )
        b2[pernr.pernr] = pernr
        
    print("Total employees read:", len(b2))
    return b2
    
    
# Returns a dict of flattened tables, specified in tables parameters
def read_tables(tables, b2_path, wildcard=False, periods=None):
    t = {}
    for x in tables:
        t[x] = []
    
    docs = []
    if periods is None:
        docs.append( read_file(b2_path, wildcard=wildcard) )
    else:
        for p in periods:
            docs.append( read_file(b2_path, wildcard=wildcard, period=p) )
            
    for doc in docs:
        btags = doc[0].xpath('//ZST_B2')
    
        i = 0
        for b in tqdm(btags):
            i = i+1
            number = b.xpath('./PERNR/text()')
            pernr = Pernr(number[0], b.xpath('./DATA')[0] )
            for x in tables:
                table = pernr.tables[x]
                table['PERNR'] = pernr.pernr
                if x == 'ZES' and not table.empty:
                    table['DATE'] = pd.to_datetime(doc[1] + table['REDAY'])
                t[x] = t[x] + [table]
    
    dfs = {}
    for x in tables:
        dfs[x] = pd.concat(t[x],sort=False)
    
    for k,v in dfs.items():
        v = v.reset_index(drop=True)
        dfs[k] = v
    
    print("Total employees read:", str(i))
    return dfs


# Reads mapping file
def read_mapping(path='input/mapping.xlsx'):
    df = pd.read_excel(path)
    mapping = {}
    for key,value in df.groupby('LEGACY'):
        mapping[key] = {x[0]:float(x[1]) for x in zip(value['SAP'],value['FACTOR'])}
    return mapping
    
# Class to include comments from previous analysis from multiple files
class Comments:
    def __init__(self, source=None, check_headcount=True, check_errors=True, check_wsr=True, check_summary=True, check_individual=True):
        self.ok = False if source is None else True
        self.check_headcount = check_headcount
        self.check_errors = check_errors
        self.check_wsr = check_wsr
        self.check_summary = check_summary
        self.check_individual = check_individual
        
        if self.ok:
            files = source if isinstance(source, list) else [source]
            for i, f in enumerate(files):              
                previo = pd.ExcelFile(f)
                print( 'File ',(i+1),f)

                # Read sheets
                if self.check_headcount:
                    prev_headcount = self._read_sheet(previo, 'Headcount', ['PERNR'])
                    self.headcount = self._merge(self.headcount, prev_headcount, ['PERNR']) if i>0 else prev_headcount
                    
                if self.check_errors: 
                    prev_errors = self._read_sheet(previo, 'Error Messages', ['PERNR', 'LDATE', 'MESTY', 'ERROR'])
                    prev_errors['ERROR'] = prev_errors['ERROR'].astype(str).str.zfill(2)
                    self.errors = self._merge(self.errors, prev_errors, ['PERNR', 'LDATE', 'MESTY', 'ERROR']) if i>0 else prev_errors
                    
                if self.check_wsr:                   
                    prev_wsr = self._read_sheet(previo, 'Not at Work Breakdown', ['SCHKZ', 'PERNR'])
                    self.wsr = self._merge(self.wsr, prev_wsr, ['SCHKZ', 'PERNR']) if i>0 else prev_wsr
                    
                if self.check_summary:                
                    prev_summary = self._read_sheet(previo, 'Summary', ['PERNR'])
                    self.summary = self._merge(self.summary, prev_summary, ['PERNR']) if i>0 else prev_summary
                    
                if self.check_individual:
                    prev_individual = self._read_sheet(previo, 'Invididual', ['PERNR', 'DATE', 'TYPE'])
                    self.individual = self._merge(self.individual, prev_individual, ['PERNR', 'DATE', 'TYPE']) if i>0 else prev_individual

    def _read_sheet(self, excel, sheetname, merge_on):
        sheet = pd.read_excel(excel, sheetname)
        sheet['PERNR'] = sheet['PERNR'].astype(str).str.zfill(8)
        seleccion = merge_on + ['Comment', 'Status']
        return sheet[seleccion]

    def _merge(self, a, b, on):
        seleccion = on + ['Comment', 'Status']
        a = a[seleccion].dropna(subset=['Comment', 'Status'], how='all')
        b = b[seleccion].dropna(subset=['Comment', 'Status'], how='all')
        c = a.merge(b, how='outer', on=on)
        
        if not c.empty:
            c['Comment'] = c.apply(lambda x: self._comment(x['Comment_x'], x['Comment_y']), axis=1)
            c['Status'] = c.apply(lambda x: self._status(x['Status_x'], x['Status_y']), axis=1)
            return c[seleccion]
        else:
            return pd.DataFrame(columns=seleccion)
        
    def _comment(self, a, b):        
        if pd.isnull(a):
            a = ''
        if pd.isnull(b):
            b = ''
        
        if a == b:
            return a
        else:
            if a == '':
                return b
            else:
                return str(a) + ' ' + str(b)
            
    def _status(self, a, b):
        if a == 'OK' or b == 'OK':
            return 'OK'
        if a == '':
            return b
        return a
    