%define package_library "no"
%define use_rust "no"
# See README

Name:       harbour-sshazam

Summary:    Shazam for SailfishOS
Version:    1.0.4
Release:    1
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

Requires: ffmpeg
Requires: ffmpeg-tools

%if %{package_library} == "yes"
Requires: pyotherside-qml-plugin-python3-qt5
BuildRequires:  python3-base
BuildRequires:  python3-devel
BuildRequires: python3-pip
BuildRequires: git
%endif

%if %{package_library} == "no"
Requires:  python3-base
Requires: gcc
Requires: python3-devel
Requires: python3-pip
%endif

%define __provides_exclude_from ^%{_datadir}/.*$
%global _missing_build_ids_terminate_build 0
%define __requires_exclude ^libgfortran-daac5196|libopenblas64_p-r0-cecebdce.*$

%description
Uses Shazam's API to recognize music


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 \
    VERSION=%{version} \
    RELEASE=%{release}

%make_build

%if %{package_library} == "yes"

%if %{use_rust} == "yes"
python3 -m pip install shazamio --target=%_builddir/deps
%else
python3 -m pip install git+https://github.com/roundedrectangle/ShazamIO --target=%_builddir/deps
%endif

python3 -m pip install pasimple --target=%_builddir/deps
rm -rf %_builddir/deps/bin

%endif

%install
%qmake5_install

%if %{package_library} == "yes"
mkdir -p %{buildroot}%{_datadir}/%{name}/lib/
cp -r deps %{buildroot}%{_datadir}/%{name}/lib/deps
%endif

desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
