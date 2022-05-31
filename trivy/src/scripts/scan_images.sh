cat <<EOF >  ~/project/.circleci/top.tpl
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      * {
        font-family: Arial, Helvetica, sans-serif;
      }
      h1 {
        text-align: center;
      }
      .group-header th {
        font-size: 200%;
      }
      .sub-header th {
        font-size: 150%;
      }
      table, th, td {
        border: 1px solid black;
        border-collapse: collapse;
        white-space: nowrap;
        padding: .3em;
      }
      table {
        margin: 0 auto;
      }
      .severity {
        text-align: center;
        font-weight: bold;
        color: #fafafa;
      }
      .severity-LOW .severity { background-color: #5fbb31; }
      .severity-MEDIUM .severity { background-color: #e9c600; }
      .severity-HIGH .severity { background-color: #ff8800; }
      .severity-CRITICAL .severity { background-color: #e40000; }
      .severity-UNKNOWN .severity { background-color: #747474; }
      .severity-LOW { background-color: #5fbb3160; }
      .severity-MEDIUM { background-color: #e9c60060; }
      .severity-HIGH { background-color: #ff880060; }
      .severity-CRITICAL { background-color: #e4000060; }
      .severity-UNKNOWN { background-color: #74747460; }
      table tr td:first-of-type {
        font-weight: bold;
      }
      .links a,
      .links[data-more-links=on] a {
        display: block;
      }
      .links[data-more-links=off] a:nth-of-type(1n+5) {
        display: none;
      }
      a.toggle-more-links { cursor: pointer; }
    </style>
    <title>{{- escapeXML ( index . 0 ).Target }} - Trivy Report - {{ now }} </title>
  </head>
  <body>

    <p>Bonjour,</p>
    <p>Nous venons de procéder au scan de sécurité de votre projet,<br /> N'hésitez pas à contacter support@donkeycode.com pour planifier les corrections</p>
EOF

cat <<EOF >  ~/project/.circleci/footer.tpl
  </body>
</html>
EOF

cat <<EOF >  ~/project/.circleci/scan_images.tpl
{{- if . }}
    <table>
    {{- range . }}
      <tr class="group-header"><th colspan="6">{{ escapeXML .Type }}</th></tr>
      {{- if (eq (len .Vulnerabilities) 0) }}
      <tr><th colspan="6">No Vulnerabilities found</th></tr>
      {{- else }}
      <tr class="sub-header">
        <th>Package</th>
        <th>Vulnerability ID</th>
        <th>Severity</th>
        <th>Installed Version</th>
        <th>Fixed Version</th>
        <th>Links</th>
      </tr>
        {{- range .Vulnerabilities }}
      <tr class="severity-{{ escapeXML .Vulnerability.Severity }}">
        <td class="pkg-name">{{ escapeXML .PkgName }}</td>
        <td>{{ escapeXML .VulnerabilityID }}</td>
        <td class="severity">{{ escapeXML .Vulnerability.Severity }}</td>
        <td class="pkg-version">{{ escapeXML .InstalledVersion }}</td>
        <td>{{ escapeXML .FixedVersion }}</td>
        <td class="links" data-more-links="off">
          {{- range .Vulnerability.References }}
          <a href={{ escapeXML . | printf "%q" }}>{{ escapeXML . }}</a>
          {{- end }}
        </td>
      </tr>
        {{- end }}
      {{- end }}
    {{- end }}
    </table>
{{- else }}
  <p>Trivy Returned Empty Report</p>
{{- end }}
EOF

cat <<EOF >  ~/project/.circleci/scan_images.sh
#!/bin/bash

mkdir -p /reports/images

images=(${IMAGES})

INDEX=0
for image in "\${images[@]}"
do
    docker pull \${image}
    echo "<h2>\${image}</h2>" > /reports/images/\${INDEX}a.html
    trivy image --format template --template "@/root/project/.circleci/scan_images.tpl" -o /reports/images/\${INDEX}b.html \${image}
    let INDEX=\${INDEX}+1
done

files=(${FILES})

mkdir -p /reports/files

INDEX=0
for file in "\${files[@]}"
do
    echo "<h2>\${file}</h2>" > /reports/files/\${INDEX}a.html
    trivy fs --format template --template "@/root/project/.circleci/scan_images.tpl" -o /reports/files/\${INDEX}b.html \${file}
    let INDEX=\${INDEX}+1
done

cat ~/project/.circleci/top.tpl > /email.html
echo "<h1>Images docker</h1>" >> /email.html
ls /reports/images/ | rev | cut -d " " -f 1 | rev | xargs -I {} cat /reports/images/{} >> /email.html
echo "<h1>Files</h1>" >> /email.html
ls /reports/files/ | rev | cut -d " " -f 1 | rev | xargs -I {} cat /reports/files/{} >> /email.html
cat ~/project/.circleci/footer.tpl >> /email.html

mv /email.html /reports/email.html
EOF

bash ~/project/.circleci/scan_images.sh